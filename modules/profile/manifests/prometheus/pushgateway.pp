class profile::prometheus::pushgateway (
    Optional[Stdlib::Fqdn] $pushgateway_host = lookup('profile::prometheus::pushgateway_host'),
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

    ferm::service { 'prometheus_pushgateway':
        proto  => 'tcp',
        port   => $http_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
