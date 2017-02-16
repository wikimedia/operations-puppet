# == Define monitoring::graphite_anomaly
# Wrapper for monitoring::service using check_graphite command.
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
#   monitoring::graphite_anomaly { 'reqstats-5xx-anomaly':
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
# upper_floor           - normalize upper band to be at least given value
# $host
# $retries
# $group
# $ensure
# $passive
# $normal
# $retry
# $contact
# $nagios_critical

define monitoring::graphite_anomaly(
    $description,
    # check_graphite check_anomaly
    $metric,
    $warning,
    $critical,
    $check_window          = 100,
    $graphite_url          = 'https://graphite.wikimedia.org',
    $timeout               = 10,
    $over                  = false,
    $under                 = false,
    $upper_floor           = undef,
    # Icinga
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $nagios_critical       = false,
    $passive               = false,
    $freshness             = 36000,
    $check_interval        = 1,
    $retry_interval        = 1,
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
    if $upper_floor != undef {
        $arg_upper_floor = "--upper-floor ${upper_floor}"
    } else {
        $arg_upper_floor = ''
    }
    $extra_args = join([$modifier, $arg_upper_floor], ' ')

    if $metric =~ /'/ {
        fail("single quotes will be stripped from graphite metric ${metric}, consider using double quotes")
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
    monitoring::service { $title:
        ensure         => $ensure,
        description    => $description,
        check_command  => "check_graphite_anomaly!${graphite_url}!${timeout}!${metric}!${warning}!${critical}!${check_window}!${extra_args}",
        retries        => $retries,
        group          => $group,
        critical       => $nagios_critical,
        passive        => $passive,
        freshness      => $freshness,
        check_interval => $check_interval,
        retry_interval => $retry_interval,
        contact_group  => $contact_group,
    }
}
