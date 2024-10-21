# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::client::limits
#
# Apply cgroup limits to stat hosts
# The stat hosts are used for data crunching,
# with data coming from Hadoop. It's easy to accidentally
# ask for too many resources, so let's limit them to preserve
# stability on these hosts.

# class { 'systemd::slice::all_users':
#     all_users_global_slice_config => template('profile/analytics/client/limits/user-resource-control.conf.erb'),

class profile::analytics::client::limits {
    # From the systemd docs for CPUQuota:
    # 'Use values > 100% for allotting CPU time on more than one CPU'
    $cpu_val = ($facts['processors']['count'] * 95)
    $cpu_quota = floor($cpu_val)
    # Cap the maximum amount of CPU % for all the combined total of all processes
    # launched by users at 95%
    systemd::override {'total-user-resources.conf':
        content => template('profile/analytics/client/limits/total-user-resource-control.conf.erb'),
        unit    => 'user.slice'
    }
    systemd::override {'individual-user-resources.conf':
        content => template('profile/analytics/client/limits/individual-user-resource-control.conf.erb'),
        # the '-' (hyphen) on the below is significant; see
        # https://www.freedesktop.org/software/systemd/man/latest/
        # user@.service.html#Controlling%20resources%20for%20logged-in%20users
        # for more details
        unit    => 'user-.slice'
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
