# == Define Resource Type: nrpe::check_disk
# This type will create a NRPE disk check with the given parameters. It serves
#  as a higher level abstraction than `nrpe::monitor_service` by exposing
#  `check_disk` specific parameters.
#
# === Parameters
#
# [*critical*]
#    see: `nrpe::monitor_service:critical`
#
# [*retries*]
#    see: `nrpe::monitor_service:retries`
#
# [*options*]
#    If given, this will be used as the options given to `check_disk`. All
#     other `check_disk` parameters will be ignored.
#    Default to undef.
#
# [*ignore_ereg_path*]
#    Array of regular expression to ignore selected path or partition.
#    Default to [ '/srv/sd[a-b][1-3]' ].
#
# [*exclude_types*]
#    Array of filesystem types to ignore.
#    Default to [ 'tracefs' ].
#
# [*warning_threshold*]
#    Check exit with WARNING status if less than *warning_threshold* units of
#     disk are free
#    Default to '6%'.
#
# [*critical_threshold*]
#    Check exit with CRITICAL status if less than *critical_threshold* units
#     of disk are free
#    Default to '3%'.
#
# [*all*]
#    Explicitly select all paths. This is equivalent to -R '.*'.
#     This part is a gross hack to workaround Varnish partitions
#     that are purposefully at 99%. Better ideas are welcome.
#    Default to true.
#
# [*paths*]
#    Path or partitions to check.
#    Default to [].
#
define nrpe::check_disk(
    $critical           = false,
    $retries            = 3,
    $options            = undef,
    $ignore_ereg_path   = [ '/srv/sd[a-b][1-3]' ],
    $exclude_types      = [ 'tracefs' ],
    $warning_threshold  = '6%',
    $critical_threshold = '3%',
    $all                = true,
    $paths              = [],
) {

    validate_string($options)
    validate_array($ignore_ereg_path)
    validate_array($exclude_types)
    validate_string($warning_threshold)
    validate_string($critical_threshold)
    validate_bool($all)

    $check_disk_options = $options ? {
        undef => template('nrpe/check_disk_options.erb'),
        default => $options,
    }

    nrpe::monitor_service { "disk_space-${title}":
        description  => "Disk space ${title}",
        critical     => $critical,
        nrpe_command => "/usr/lib/nagios/plugins/check_disk ${check_disk_options}",
        retries      => $retries,
    }
}
