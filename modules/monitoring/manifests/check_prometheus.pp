# == Define monitoring::check_prometheus
#
# Setup an alert based on a Prometheus query. The result of the query must be a
# scalar to be compared against a threshold.
#
# == Usage
#
# Check for load average on a single host. Note that the result must be a
# scalar to be compared against a threshold, hence scalar().
#
#   monitoring::check_prometheus { 'loadavg-1min':
#       description    => 'High one minute load average',
#       query          => "scalar(node_load1{instance=\"${::hostname}:9100\"})",
#       prometheus_url => "http://prometheus.svc.${::site}.wmnet/ops",
#       warning        => 5,
#       critical       => 10,
#   }
#
# Another example: compare 1min load average and the number of CPUs, alert if
# the former exceeds the latter. Note that the expression could be simplified,
# e.g. by recording the number of CPUs as a different metric:
# https://prometheus.io/docs/practices/rules/
#
#   monitoring::check_prometheus { 'loadavg-1min-vs-cpus':
#       description    => 'load average exceeds the number of CPUs',
#       query          => "scalar(node_load1{instance=\"${::hostname}:9100\"}) / scalar(count(node_cpu{instance=\"${::hostname}:9100\",mode=\"idle\"}) by (instance))",
#       prometheus_url => "http://prometheus.svc.${::site}.wmnet/ops",
#       warning        => 0.7,
#       critical       => 1,
#   }
#
# == Parameters
#
# [*description*]
#   Icinga description
#
# [*query*]
#   The prometheus query to run. Note that the result must be a scalar, see
#   also https://prometheus.io/docs/querying/basics/#expression-language-data-types
#
# [*prometheus_url*]
#   The url to a prometheus server instance.
#
# [*warning*]
#   Warning threshold
#
# [*critical*]
#   Critical threshold
#
# [*method*]
#   Threshold comparison method. One of gt, ge, lt, le, eq, ne
#
# [*nan_ok*]
#   Is NaN considered an OK result?
#
# [*retries*]
#   How many times (IOW, minutes) to retry before considering this check in
#   HARD state.
#
# [*group*]
#   Icinga service group.
#
# [*ensure*]
#   Puppet ensure, absent/present
#
# [*nagios_critical*]
#   Notify via paging if this check fails
#
# [*contact_group*]
#   What contact groups to use for notifications

define monitoring::check_prometheus(
    $description,
    $query,
    $prometheus_url,
    $warning,
    $critical,
    $method          = 'ge',
    $nan_ok          = false,
    $retries         = 5,
    $group           = undef,
    $ensure          = present,
    $nagios_critical = false,
    $contact_group   = 'admins'
)
{
    validate_re($method, '^(gt|ge|lt|le|eq|ne)$')
    validate_bool($nan_ok)

    $command = $nan_ok ? {
        true    => 'check_prometheus_nan_ok',
        default => 'check_prometheus',
    }

    monitoring::service { $title:
        ensure        => $ensure,
        description   => $description,
        check_command => "${command}!${query}!${prometheus_url}!${warning}!${critical}!${title}!${method}",
        retries       => $retries,
        group         => $group,
        critical      => $nagios_critical,
        contact_group => $contact_group,
    }
}
