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
# $description     - Description of icinga alert
# $metric          - graphite metric name
# $warning         - alert warning datapoints
# $critical        - alert critical datapoints
# $check_window    - the number of datapoints on which the check
#                    is performed. Defaults to 100.
# $graphite_url    - URL of the graphite server.
# $timeout         - Timeout for the http query to
#                    graphite. Defaults to 10 seconds
# $over            - check only for values above the limit
# $under           - check only for values below the limit
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

define monitoring::graphite_anomaly(
    $description,
    $metric,
    $warning,
    $critical,
    $dashboard_links,
    $check_window    = 100,
    $graphite_url    = 'https://graphite.wikimedia.org',
    $timeout         = 10,
    $over            = false,
    $under           = false,
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
        $notes_urls = $dashboard_links.reduce('') |$urls, $dashboard_link| {
            "${urls}'${dashboard_link}' "
        }
    }

    if $over == true {
        $modifier = '--over'
    }
    elsif $under == true {
        $modifier = '--under'
    }
    else {
        $modifier = ''
    }

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
        check_command  => "check_graphite_anomaly!${graphite_url}!${timeout}!${metric}!${warning}!${critical}!${check_window}!${modifier}",
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
