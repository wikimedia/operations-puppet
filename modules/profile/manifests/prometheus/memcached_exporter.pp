class profile::prometheus::memcached_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
    $prometheus_dns_record_type = hiera('profile::prometheus::dns_record_type', 'AAAA'),
) {
    prometheus::memcached_exporter { 'default': }
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), ${prometheus_dns_record_type}))"

    ferm::service { 'prometheus-memcached-exporter':
        proto  => 'tcp',
        port   => '9150',
        srange => $ferm_srange,
    }
}
