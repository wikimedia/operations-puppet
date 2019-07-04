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
# $notes_link      - Link to a wiki article to help resolve issues
#                    This will be combined with dashboard_links to produce
#                    the notes_url array.
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
    String[1]                        $description,
    String[1]                        $metric,
    Numeric                          $warning,
    Numeric                          $critical,
    Array[Monitoring::Graphite::Url] $dashboard_links,
    Stdlib::HTTPUrl                  $notes_link,
    Boolean                          $series          = false,
    Monitoring::Graphite::Period     $from            = '10min',
    Monitoring::Graphite::Period     $until           = '0min',
    Numeric                          $percentage      = 1,
    Boolean                          $under           = false,
    Stdlib::HTTPUrl                  $graphite_url    = 'https://graphite.wikimedia.org',
    Integer[1,60]                    $timeout         = 10,
    Stdlib::Host                     $host            = $::hostname,
    Integer[1,10]                    $retries         = 3,
    Optional[String[1]]              $group           = undef,
    String[1]                        $ensure          = present,
    Boolean                          $nagios_critical = false,
    Boolean                          $passive         = false,
    Integer[1]                       $freshness       = 36000,
    Integer[1]                       $check_interval  = 1,
    Integer[1]                       $retry_interval  = 1,
    String                           $contact_group   = 'admins',
) {

    $link_fail_message = 'The $dashboard_links and $notes_links URLs must not be URL-encoded'
    # notes link always has to com first to ensure the correct icon is used in icinga
    # we start with `[]` so puppet knows we want a array
    $links = [] + $notes_link + $dashboard_links

    $notes_urls = $links.reduce('') |$urls, $link| {
        if $link =~ /%\h\h/ {
            fail($link_fail_message)
        }
        "${urls}'${link}' "
    }.strip

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
