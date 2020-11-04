class profile::alertmanager::ack (
    Stdlib::Host        $active_host = lookup('profile::alertmanager::active_host'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
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

    $hosts = join($prometheus_nodes, ' ')
    ferm::service { 'alertmanager-ack':
        proto  => 'tcp',
        port   => $http_port,
        srange => "@resolve((${hosts}))",
    }
}
