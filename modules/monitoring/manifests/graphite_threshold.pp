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
# $description     - Description of icinga alert
# $metric          - graphite metric name
# $warning         - alert warning threshold
# $critical        - alert critical threshold
# $series          - true if the metric refers to a series of graphite
#                    datapoints that should be checked individually
# $from            - Date from which to fetch data.
#                    Examples: '1hours','10min' (default), '2w'
# $until           - end sampling date (negative relative time from
#                    now.  Default: '0min'
# $percentage      - Number of datapoints exceeding the
#                    threshold. Defaults to 1%.
# $under           - If true, the threshold is a lower limit.
#                    Defaults to false.
# $graphite_url    - URL of the graphite server.
# $timeout         - Timeout for the http query to
#                    graphite. Defaults to 10 seconds
# $dashboard_links - Links to the Grafana dashboard for this alarm
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
    $dashboard_links,
    $series          = false,
    $from            = '10min',
    $until           = '0min',
    $percentage      = 1,
    $under           = false,
    $graphite_url    = 'https://graphite.wikimedia.org',
    $timeout         = 10,
    $host            = $::hostname,
    $retries         = 3,
    $group           = undef,
    $ensure          = present,
    $nagios_critical = false,
    $passive         = false,
    $freshness       = 36000,
    $check_interval  = 1,
    $retry_interval  = 1,
    $contact_group   = 'admins',
)
{
    validate_array($dashboard_links)

    # Validate the dashboard_links and generate the notes_urls
    if size($dashboard_links) < 1 {
        fail('The $dashboard_links array cannot be empty')
    } elsif size($dashboard_links) == 1 {
        # Puppet reduce doesn't call the lambda if there is only one element
        validate_re($dashboard_links[0], '^https:\/\/grafana\.wikimedia\.org')
        $notes_urls = "'${dashboard_links[0]}'"
    } else {
        $dashboard_links.each |$dashboard_link| {
            validate_re($dashboard_link, '^https:\/\/grafana\.wikimedia\.org')
        }
        $dashboard_links.reduce('') |$notes_urls, $dashboard_link| {
            "${notes_urls}'${dashboard_link}' "
        }
    }

    # checkcommands.cfg's check_graphite_threshold command has
    # many positional arguments that
    # are passed to the check_graphite script:
    #   $ARG1$  -U url
    #   $ARG2$  -T timeout
    #   $ARG3$  the metric to monitor
    #   $ARG4$  -W warning threshold
    #   $ARG5$  -C critical threshold
    #   $ARG6$  --from start sampling date (negative relative time from now)
    #   $ARG7$  --until end sampling date (negative relative time from now)
    #   $ARG8$  --perc percentage of exceeding datapoints
    #   $ARG9$  --over or --under
    $modifier = $under ? {
        true  => '--under',
        default => '--over'
    }

    if $metric =~ /'/ {
        fail("single quotes will be stripped from graphite metric ${metric}, consider using double quotes")
    }

    $command = $series ? {
        true    => 'check_graphite_series_threshold',
        default => 'check_graphite_threshold'
    }

    monitoring::service { $title:
        ensure         => $ensure,
        description    => $description,
        check_command  => "${command}!${graphite_url}!${timeout}!${metric}!${warning}!${critical}!${from}!${until}!${percentage}!${modifier}",
        retries        => $retries,
        group          => $group,
        critical       => $nagios_critical,
        passive        => $passive,
        freshness      => $freshness,
        check_interval => $check_interval,
        retry_interval => $retry_interval,
        contact_group  => $contact_group,
        notes_url      => $notes_urls,
    }
}
