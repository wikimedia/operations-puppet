# Send logs to a central server
class role::toollabs::logging::sender(
    $centralserver,
) {
    $centralip = ipresolve($centralserver, 4, $::nameservers[0])
    rsyslog::conf{ 'everything':
        content => template('role/toollabs/sendlogs.conf.erb')
    }
}
