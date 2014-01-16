# nagios.pp

import "generic-definitions.pp"
import "decommissioning.pp"

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

    # Export the nagios host instance
    @@nagios_host { $title:
        ensure               => $ensure,
        target               => "${nagios_config_dir}/puppet_hosts.cfg",
        host_name            => $title,
        address              => $ip_address,
        hostgroups           => $group ? {
            /.+/    => $group,
            default => undef,
        },
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
        $image = $operatingsystem ? {
            'Ubuntu'  => 'ubuntu',
            'Solaris' => 'sunlogo',
            default   => 'linux40'
        }

        # Couple it with some hostextinfo
        @@nagios_hostextinfo { $title:
            ensure          => $ensure,
            target          => "${nagios_config_dir}/puppet_hostextinfo.cfg",
            host_name       => $title,
            notes           => $title,
            # Needs c       = cluster parameter. Let's fix this cleanly with Puppet 2.6 hashes
            notes_url       => "${ganglia_url}/?c=${ganglia::cname}&h=${fqdn}&m=&r=hour&s=descending&hc=4",
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
    $group                 = $nagios_group,
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

    if $::hostname in $::decommissioned_servers {
        # Export the nagios service instance
        @@nagios_service { "$::hostname $title":
            ensure                        => 'absent',
            target                        => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
            host_name                     => $host,
            servicegroups                 => $group ? {
                /.+/    => $group,
                default => undef,
            },
            service_description           => $description,
            check_command                 => $check_command,
            max_check_attempts            => $retries,
            normal_check_interval         => $normal_check_interval,
            retry_check_interval          => $retry_check_interval,
            check_period                  => '24x7',
            notification_interval         => 0,
            notification_period           => '24x7',
            notification_options          => 'c,r,f',
            contact_groups                => $critical ? {
                'true'  => 'admins,sms',
                default => $contact_group,
            },
        }
    }
    else {
        # Export the nagios service instance
        @@nagios_service { "$::hostname $title":
            ensure                  => $ensure,
            target                  => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
            host_name               => $host,
            servicegroups           => $group ? {
                /.+/    => $group,
                default => undef
            },
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
}

define monitor_group ($description, $ensure=present) {
    # Nagios hostgroup instance
    nagios_hostgroup { $title:
        ensure         => $ensure,
        target         => "${nagios_config_dir}/puppet_hostgroups.cfg",
        hostgroup_name => $title,
        alias          => $description,
    }

    # Nagios servicegroup instance
    nagios_servicegroup { $title:
        ensure            => $ensure,
        target            => "${nagios_config_dir}/puppet_servicegroups.cfg",
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

class misc::zfs::monitoring {
    monitor_service { 'zfs raid':
        description   => 'ZFS RAID',
        check_command => 'nrpe_check_zfs',
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
# ( Pasted from# https://github.com/wikimedia/operations-debs-check_ganglia#specifying-threshold-values )
#
# == Usage
#   # Alert if free space in HDFS is less than 1TB
#   monitor_ganglia { 'hdfs-capacity-remaining':
#       description          => 'GB free in HDFS',
#       metric               => 'Hadoop.NameNode.FSNamesystem.CapacityRemainingGB',
#       warning_threshold    => ':1024',
#       critical_threshold   => ':512,
#   }
#
# == Parameters
# $description          - Description of icinga alert
# $metric               - ganglia metric name
# $warning              - alert warning threshold
# $critical_threshold   - alert critical threshold
# $gmetad_host          - Default: 'nickel.wikimedia.org'
# $gmetad_query_port    - gmetad XML query interface port.  Default: 8654
# $host
# $retries
# $group
# $ensure
# $critical
# $passive
# $freshness
# $normal_check_interval
# $retry_check_interval
# $contact_group
#
define monitor_ganglia(
    $description,
    $metric,
    $warning_threshold,
    $critical_threshold,
    $gmetad_host           = 'nickel.wikimedia.org',
    $gmetad_query_port     = 8654,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = $nagios_group,
    $ensure                = present,
    $critical              = 'false',
    $passive               = 'false',
    $freshness             = 36000,
    $normal_check_interval = 1,
    $retry_check_interval  = 1,
    $contact_group         = 'admins'
)
{
    Class['icinga::ganglia::check'] -> Monitor_ganglia[$title]

    # checkcommands.cfg's check_ganglia command has
    # many positional arguments that
    # are passed to check_ganglia script:
    #   $ARG1$  -g gmetad host
    #   $ARG2$  -p gmetad xml query port
    #   $ARG3$  -m ganglia metric name
    #   $ARG4$  -w warning threshold
    #   $ARG5$  -c critical threshold

     monitor_service { $title:
         ensure                => $ensure,
         description           => $description,
         check_command         => "check_ganglia!${gmetad_host}!${gmetad_query_port}!${metric}!${warning_threshold}!${critical_threshold}",
         retries               => $retries,
         group                 => $group,
         critical              => $critical,
         passive               => $passive,
         freshness             => $freshness,
         normal_check_interval => $normal_check_interval,
         retry_check_interval  => $retry_check_interval,
         contact_group         => $contact_group,
     }
}
