# Send logs to a central server
#
# filtertags: labs-project-tools
class role::toollabs::logging::sender(
    $centralserver_ips,
) {
    rsyslog::conf{ 'everything':
        content => template('role/toollabs/sendlogs.conf.erb'),
    }
}
