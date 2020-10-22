class profile::prometheus::pushgateway (
    Optional[Stdlib::Fqdn] $pushgateway_host = lookup('profile::prometheus::pushgateway_host'),
    Array $prometheus_nodes = lookup('prometheus_nodes'),
) {
    $http_port = 9091

    if $pushgateway_host == $::fqdn {
        $ensure = present
    } else {
        $ensure = absent
    }

    class { 'prometheus::pushgateway':
        ensure      => $ensure,
        listen_port => $http_port,
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'prometheus_pushgateway':
        proto  => 'tcp',
        port   => $http_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
