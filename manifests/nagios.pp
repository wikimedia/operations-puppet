# nagios.pp

$nagios_config_dir = '/etc/nagios'

$ganglia_url = 'http://ganglia.wikimedia.org'

define monitor_host(
    $ip_address    = $::ipaddress,
    $group         = $nagios_group,
    $ensure        = present,
    $critical      = 'false',
    $contact_group = 'admins'
)
{
    if ! $ip_address {
        fail("Parameter $ip_address not defined!")
    }

    # Determine the hostgroup:
    # If defined in the declaration of resource, we use it;
    # If not, adopt the standard format
    $hostgroup = $group ? {
        /.+/    => $group,
        default => $cluster ? {
            default => "${cluster}_${::site}"
        }
    }

    # Export the nagios host instance
    @@nagios_host { $title:
        ensure               => $ensure,
        target               => "${::nagios_config_dir}/puppet_hosts.cfg",
        host_name            => $title,
        address              => $ip_address,
        hostgroups           => $hostgroup,
        check_command        => 'check_ping!500,20%!2000,100%',
        check_period         => '24x7',
        max_check_attempts   => 2,
        contact_groups       => $critical ? {
            'true'  => 'admins,sms',
            default => $contact_group,
        },
        notification_interval => 0,
        notification_period   => '24x7',
        notification_options  => 'd,u,r,f',
    }

    if $title == $::hostname {
        $image = $::operatingsystem ? {
            'Ubuntu'  => 'ubuntu',
            default   => 'linux40'
        }

        # Couple it with some hostextinfo
        @@nagios_hostextinfo { $title:
            ensure          => $ensure,
            target          => "${::nagios_config_dir}/puppet_hostextinfo.cfg",
            host_name       => $title,
            notes           => $title,
            icon_image      => "${image}.png",
            vrml_image      => "${image}.png",
            statusmap_image => "${image}.gd2",
        }
    }
}

define monitor_service(
    $description,
    $check_command,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $critical              = 'false',
    $passive               = 'false',
    $freshness             = 36000,
    $normal_check_interval = 1,
    $retry_check_interval  = 1,
    $contact_group         = 'admins'
)
{
    if ! $host {
        fail("Parameter $host not defined!")
    }

    if $group != undef {
        $servicegroup = $group
    }
    elsif $nagios_group != undef {
        # nagios group should be defined at the node level with hiera.
        $servicegroup = $nagios_group
    } else {
        # this check is part of no servicegroup.
        $servicegroup = undef
    }

        # Export the nagios service instance
        @@nagios_service { "$::hostname $title":
            ensure                  => $ensure,
            target                  => "${::nagios_config_dir}/puppet_checks.d/${host}.cfg",
            host_name               => $host,
            servicegroups           => $servicegroup,
            service_description     => $description,
            check_command           => $check_command,
            max_check_attempts      => $retries,
            normal_check_interval   => $normal_check_interval,
            retry_check_interval    => $retry_check_interval,
            check_period            => '24x7',
            notification_interval   => $critical ? {
                'true'  => 240,
                default => 0,
            },
            notification_period     => '24x7',
            notification_options    => 'c,r,f',
            contact_groups          => $critical ? {
                'true'  => 'admins,sms',
                default => $contact_group,
            },
            passive_checks_enabled  => 1,
            active_checks_enabled   => $passive ? {
                'true'  => 0,
                default => 1,
            },
            is_volatile             => $passive ? {
                'true'  => 1,
                default => 0,
            },
            check_freshness         => $passive ? {
                'true'  => 1,
                default => 0,
            },
            freshness_threshold     => $passive ? {
                'true'  => $freshness,
                default => undef,
            },
    }
}

define monitor_group ($description, $ensure=present) {
    # Nagios hostgroup instance
    nagios_hostgroup { $title:
        ensure         => $ensure,
        target         => "${::nagios_config_dir}/puppet_hostgroups.cfg",
        hostgroup_name => $title,
        alias          => $description,
    }

    # Nagios servicegroup instance
    nagios_servicegroup { $title:
        ensure            => $ensure,
        target            => "${::nagios_config_dir}/puppet_servicegroups.cfg",
        servicegroup_name => $title,
        alias             => $description,
    }
}
define decommission_monitor_host {
    if defined(Nagios_host[$title]) {
        # Override the existing resources
        Nagios_host <| title == $title |> {
            ensure => absent
        }
        Nagios_hostextinfo <| title == $title |> {
            ensure => absent
        }
    }
    else {
        # Resources don't exist in Puppet. Remove from Nagios config as well.
        nagios_host { $title:
            host_name => $title,
            ensure    => absent;

        }
        nagios_hostextinfo { $title:
            host_name => $title,
            ensure    => absent;

        }
    }
}

class nagios::gsbmonitoring {
    @monitor_host { 'google':
        ip_address => '74.125.225.84',
    }

    @monitor_service { 'GSB_mediawiki':
        description   => 'check google safe browsing for mediawiki.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=mediawiki.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wikibooks':
        description   => 'check google safe browsing for wikibooks.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikibooks.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wikimedia':
        description   => 'check google safe browsing for wikimedia.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikimedia.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wikinews':
        description   => 'check google safe browsing for wikinews.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikinews.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wikipedia':
        description   => 'check google safe browsing for wikipedia.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikipedia.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wikiquotes':
        description   => 'check google safe browsing for wikiquotes.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiquotes.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wikisource':
        description   => 'check google safe browsing for wikisource.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikisource.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wikiversity':
        description   => 'check google safe browsing for wikiversity.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiversity.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitor_service { 'GSB_wiktionary':
        description   => 'check google safe browsing for wiktionary.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wiktionary.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
}

class nagios::group {
    group { 'nagios':
        ensure    => present,
        name      => 'nagios',
        system    => true,
        allowdupe => false,
    }
}

# == Define monitor_ganglia
# Wrapper for monitor_service using check_ganglia command.
# This allows you to monitor arbitrary values in ganglia
# with icinga without having to add entries to checkcommands.cfg.erb
#
# Specifying threshold values
# ===========================
#
# (This is extracted from ``check_gmond.checkval``; see the embedded
# documentation for the most current version).
#
# The arguments to the ``-w`` and ``-c`` options use the following syntax:
#
# For numeric values
# ------------------
# - 5       -- match if v >= 5
# - 3:5     -- match if 3 <= v <= 5
# - :5      -- match if v <=5
# - 1,2,3   -- match if v in (1,2,3)
#
# For string values
# ------------------
# - foo     -- match if v == foo
# - foo,bar -- match if v in (foo, bar)
#
# Negation
# --------
# You can negate a threshold expression by preceding it with '!'.  For
# example:
#
# - !5      -- match if v < 5
# - !3:5    -- match if v<3 || v>5
# - !1,2,3  -- match if v not in (1,2,3)
#
# ( Pasted from#
# https://github.com/wikimedia/operations-debs-check_ganglia#specifying-threshold-values
# )
#
# == Usage
#   # Alert if free space in HDFS is less than 1TB
#   monitor_ganglia { 'hdfs-capacity-remaining':
#       description          => 'GB free in HDFS',
#       metric               =>
#       'Hadoop.NameNode.FSNamesystem.CapacityRemainingGB',
#       warning              => ':1024',
#       critical             => ':512,
#   }
#
# == Parameters
# $description          - Description of icinga alert
# $metric               - ganglia metric name
# $warning              - alert warning threshold
# $critical             - alert critical threshold
# $metric_host          - hostname in ganglia we want to monitor.
#                         Can't use nagios macro in checkcommands.cfg
#                         because fqdn is not available.
#                         Default: $::fqdn of this node
# $gmetad_host          - Default: 'nickel.wikimedia.org'
# $gmetad_query_port    - gmetad XML query interface port.  Default: 8654
# $host
# $retries
# $group
# $ensure
# $nagios_critical      - passed as $critical to monitor_service define
# $passive
# $freshness
# $normal_check_interval
# $retry_check_interval
# $contact_group
#
define monitor_ganglia(
    $description,
    $metric,
    $warning,
    $critical,
    $metric_host           = $::fqdn,
    $gmetad_host           = 'nickel.wikimedia.org',
    $gmetad_query_port     = 8654,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $nagios_critical       = 'false',
    $passive               = 'false',
    $freshness             = 36000,
    $normal_check_interval = 3,
    $retry_check_interval  = 3,
    $contact_group         = 'admins'
)
{
    # Service group for ganglia checks
    # If defined in the declaration of resource, we use it;
    # If not, 'misc' servers have no hostgroup, the others adopt the
    # standard format
    $ganglia_group = $group ? {
        /.+/    => $group,
        default => $cluster ? {
            'misc'  => undef,
            default => "${cluster}_${::site}"
        }
    }

    # checkcommands.cfg's check_ganglia command has
    # many positional arguments that
    # are passed to check_ganglia script:
    #   $ARG1$  -g gmetad host
    #   $ARG2$  -p gmetad xml query port
    #   $ARG3$  -H Host for which we want metrics
    #   $ARG4$  -m ganglia metric name
    #   $ARG5$  -w warning threshold
    #   $ARG6$  -c critical threshold
    #   $ARG7$  -C ganglia cluster name

    monitor_service { $title:
        ensure                => $ensure,
        description           => $description,
        check_command         => "check_ganglia!${gmetad_host}!${gmetad_query_port}!${metric_host}!${metric}!${warning}!${critical}!${::ganglia::cname}",
        retries               => $retries,
        group                 => $ganglia_group,
        critical              => $nagios_critical,
        passive               => $passive,
        freshness             => $freshness,
        normal_check_interval => $normal_check_interval,
        retry_check_interval  => $retry_check_interval,
        contact_group         => $contact_group,
    }
}




# == Define monitor_graphite_threshold
# Wrapper for monitor_service using check_graphite command.
# This allows you to monitor arbitrary metrics in graphite
# with icinga without having to add entries to checkcommands.cfg.erb
#
# Check type
# =====================
# A simple threshold checking is supported -this simply checks if a
# given percentage of the data points in the interested interval
# exceeds a threshold.
#
#
# == Usage
#   # Alert if the same metric exceeds an absolute threshold 5% of
#   # times.
#   monitor_graphite_threshold { 'reqstats-5xx':
#       description          => 'Number of 5xx responses',
#       metric               => 'reqstats.5xx',
#       warning              => 250,
#       critical             => 500,
#       from                 => '1hours',
#       percentage           => 5,
#   }
# == Parameters
# $description          - Description of icinga alert
# $metric               - graphite metric name
# $warning              - alert warning threshold
# $critical             - alert critical threshold
# $series               - true if the metric refers to a series of graphite
#                         datapoints that should be checked individually
# $from                 - Date from which to fetch data.
#                         Examples: '1hours','10min' (default), '2w'
# $percentage           - Number of datapoints exceeding the
#                         threshold. Defaults to 1%.
# $under                - If true, the threshold is a lower limit.
#                         Defaults to false.
# $graphite_url         - URL of the graphite server.
# $timeout              - Timeout for the http query to
#                         graphite. Defaults to 10 seconds
# $host
# $retries
# $group
# $ensure
# $passive
# $normal
# $retry
# $contact
# $nagios_critical

define monitor_graphite_threshold(
    $description,
    $metric,
    $warning,
    $critical,
    $series                = false,
    $from                  = '10min',
    $percentage            = 1,
    $under                 = false,
    $graphite_url          = 'http://graphite.wikimedia.org',
    $timeout               = 10,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $nagios_critical       = 'false',
    $passive               = 'false',
    $freshness             = 36000,
    $normal_check_interval = 1,
    $retry_check_interval  = 1,
    $contact_group         = 'admins'
)
{


    # checkcommands.cfg's check_graphite_threshold command has
    # many positional arguments that
    # are passed to the check_graphite script:
    #   $ARG1$  -U url
    #   $ARG2$  -T timeout
    #   $ARG3$  the metric to monitor
    #   $ARG4$  -W warning threshold
    #   $ARG5$  -C critical threshold
    #   $ARG6$  --from start sampling date
    #   $ARG7$  --perc percentage of exceeding datapoints
    #   $ARG8$  --over or --under
    $modifier = $under ? {
        true  => '--under',
        default => '--over'
    }
    $command = $series ? {
        true    => 'check_graphite_series_threshold',
        default => 'check_graphite_threshold'
    }
    monitor_service { $title:
        ensure                => $ensure,
        description           => $description,
        check_command         => "${command}!${graphite_url}!${timeout}!${metric}!${warning}!${critical}!${from}!${percentage}!${modifier}",
        retries               => $retries,
        group                 => $group,
        critical              => $nagios_critical,
        passive               => $passive,
        freshness             => $freshness,
        normal_check_interval => $normal_check_interval,
        retry_check_interval  => $retry_check_interval,
        contact_group         => $contact_group,
    }
}


# == Define monitor_graphite_anomaly
# Wrapper for monitor_service using check_graphite command.
# This allows you to monitor arbitrary metrics in graphite
# with icinga without having to add entries to checkcommands.cfg.erb
#
# Check type
# =====================
# A very simple predictive checking is also
# supported - it will check if more than N points in a given
# range of datapoints are outside of the Holt-Winters confidence
# bands, as calculated by graphite (see
# http://bit.ly/graphiteHoltWinters).
#
#
# == Usage
#   # Alert if an anomaly is found in the number of 5xx responses
#   monitor_graphite_anomaly { 'reqstats-5xx-anomaly':
#       description          => 'Anomaly in number of 5xx responses',
#       metric               => 'reqstats.5xx',
#       warning              => 5,
#       critical             => 10,
#       over                 => true
#   }
#
# == Parameters
# $description          - Description of icinga alert
# $metric               - graphite metric name
# $warning              - alert warning datapoints
# $critical             - alert critical datapoints
# $check_window         - the number of datapoints on which the check
#                         is performed. Defaults to 100.
# $graphite_url         - URL of the graphite server.
# $timeout              - Timeout for the http query to
#                         graphite. Defaults to 10 seconds
# over                  - check only for values above the limit
# under                 - check only for values below the limit
# $host
# $retries
# $group
# $ensure
# $passive
# $normal
# $retry
# $contact
# $nagios_critical

define monitor_graphite_anomaly(
    $description,
    $metric,
    $warning,
    $critical,
    $check_window          = 100,
    $graphite_url          = 'http://graphite.wikimedia.org',
    $timeout               = 10,
    $over                  = false,
    $under                 = false,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $nagios_critical       = 'false',
    $passive               = 'false',
    $freshness             = 36000,
    $normal_check_interval = 1,
    $retry_check_interval  = 1,
    $contact_group         = 'admins'
)
{

    if $over == true {
        $modifier = '--over'
    }
    elsif $under == true {
        $modifier = '--under'
    }
    else {
        $modifier = ''
    }
    # checkcommands.cfg's check_graphite_anomaly command has
    # many positional arguments that
    # are passed to the check_graphite script:
    #   $ARG1$  -U url
    #   $ARG2$  -T timeout
    #   $ARG3$  the metric to monitor
    #   $ARG4$  -W warning threshold
    #   $ARG5$  -C critical threshold
    #   $ARG6$  --check_window sampling size
    #   $ARG7$  --over or --under
    monitor_service { $title:
        ensure                => $ensure,
        description           => $description,
        check_command         => "check_graphite_anomaly!${graphite_url}!${timeout}!${metric}!${warning}!${critical}!${check_window}!$modifier",
        retries               => $retries,
        group                 => $group,
        critical              => $nagios_critical,
        passive               => $passive,
        freshness             => $freshness,
        normal_check_interval => $normal_check_interval,
        retry_check_interval  => $retry_check_interval,
        contact_group         => $contact_group,
    }
}
