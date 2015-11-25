# == Define monitoring::graphite_threshold
# Wrapper for monitoring::service using check_graphite command.
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
#   monitoring::graphite_threshold { 'reqstats-5xx':
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

define monitoring::graphite_threshold(
    $description,
    $metric,
    $warning,
    $critical,
    $series                = false,
    $from                  = '10min',
    # temporarly use $until to conditionally use check_graphite_until command
    $until                 = undef,
    $percentage            = 1,
    $under                 = false,
    $graphite_url          = 'http://graphite.wikimedia.org',
    $timeout               = 10,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $nagios_critical       = false,
    $passive               = false,
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
    #   $ARG6$  --from start sampling date (negative relative time from now)
    #####   $ARG7$  --until end sampling date (negative relative time from now)
    #   $ARG8$  --perc percentage of exceeding datapoints
    #   $ARG9$  --over or --under
    $modifier = $under ? {
        true  => '--under',
        default => '--over'
    }

    if $metric =~ /'/ {
        fail("single quotes will be stripped from graphite metric ${metric}, consider using double quotes")
    }

    # TEMPORARY conditional to test the --until arg without affecting all
    # alerts. This conditional will be removed once we are sure until works.
    if $until and !$series {
        $command = 'check_graphite_threshold_until_temp'

        monitoring::service { $title:
            ensure                => $ensure,
            description           => $description,
            check_command         => "${command}!${graphite_url}!${timeout}!${metric}!${warning}!${critical}!${from}!${until}!${percentage}!${modifier}",
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
    else {
        $command = $series ? {
            true    => 'check_graphite_series_threshold',
            default => 'check_graphite_threshold'
        }

        monitoring::service { $title:
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
}
