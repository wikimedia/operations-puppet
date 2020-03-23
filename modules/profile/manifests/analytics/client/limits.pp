# == Class profile::analytics::client::limits
#
# Add basic systemd cgroup user limits to Analytics clients.
# Most of the Analytics clients are used for data crunching
# with data coming from Hadoop, often leading to out of memory
# events and icinga alerts.
#
class profile::analytics::client::limits {

    # Allow a single unit to use maximum 80% of the CPU resources
    # From the systemd docs for CPUQuota:
    # 'Use values > 100% for allotting CPU time on more than one CPU'
    $cpu_quota = floor($facts['processors']['count'] * 0.9) * 100

    class { 'systemd::slice::all_users':
        all_users_global_slice_config => template('profile/analytics/client/limits/user-resource-control.conf.erb'),
    }

    # By default the cron.service unit runs under the system.slice.
    # This means that all crontab's processes escape the limits imposed
    # by the user.slice, so an explicit override is needed.
    $cron_slice = 'user.slice'
    systemd::unit { 'cron':
        ensure   => present,
        content  => template('profile/analytics/client/limits/cron-override.systemd.erb'),
        restart  => false,
        override => true,
    }

}
