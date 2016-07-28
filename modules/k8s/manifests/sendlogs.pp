# Send logs to a central server
class k8s::sendlogs(
    $centralserver,
) {
    $centralip = ipresolve($centralserver, 4, $::nameservers[0])
    rsyslog::conf{ 'everything':
        content => template('k8s/sendlogs.conf.erb')
    }
}