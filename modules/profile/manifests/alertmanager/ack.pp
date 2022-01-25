class profile::alertmanager::ack (
    Stdlib::Host        $active_host = lookup('profile::alertmanager::active_host'),
) {
    if $active_host == $::fqdn {
        $ensure = present
    } else {
        $ensure = absent
    }

    $http_port = 19195

    class { 'alertmanager::ack':
        ensure      => $ensure,
        listen_port => $http_port,
    }
}
