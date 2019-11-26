# == Class profile::analytics::client::limits
#
# Add basic systemd cgroup user limits to Analytics clients.
# Most of the Analytics clients are used for data crunching
# with data coming from Hadoop, often leading to out of memory
# events and icinga alerts.
#
class profile::analytics::client::limits {

    class { 'systemd::slice::all_users':
        all_users_slice_config  => file('profile/analytics/client/limits/user-resource-control.conf'),
    }
}
