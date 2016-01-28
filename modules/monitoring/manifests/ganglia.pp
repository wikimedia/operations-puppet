# == Define monitoring::ganglia
# Wrapper for monitoring::service using check_ganglia command.
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
#   monitoring::ganglia { 'hdfs-capacity-remaining':
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
# $gmetad_host          - Default: 'uranium.wikimedia.org'
# $gmetad_query_port    - gmetad XML query interface port.  Default: 8654
# $host
# $retries
# $group
# $ensure
# $nagios_critical      - passed as $critical to monitoring::service define
# $passive
# $freshness
# $normal_check_interval
# $retry_check_interval
# $contact_group
#
define monitoring::ganglia(
    $description,
    $metric,
    $warning,
    $critical,
    $metric_host           = $::fqdn,
    $gmetad_host           = 'uranium.wikimedia.org',
    $gmetad_query_port     = 8654,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $nagios_critical       = false,
    $passive               = false,
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
        default => $::cluster ? {
            'misc'  => undef,
            default => "${::cluster}_${::site}"
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

    monitoring::service { $title:
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
