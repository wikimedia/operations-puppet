# Send logs to a central server
class role::toollabs::logging::sender(
    $centralserver_ips,
) {
    rsyslog::conf{ 'everything':
        content => template('role/toollabs/sendlogs.conf.erb')
    }
}
