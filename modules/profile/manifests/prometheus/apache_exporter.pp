class profile::prometheus::apache_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
    $prometheus_dns_record_type = hiera('profile::prometheus::dns_record_type', 'AAAA'),
) {
    prometheus::apache_exporter { 'default': }
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), ${prometheus_dns_record_type}))"

    ferm::service { 'prometheus-apache_exporter':
        proto  => 'tcp',
        port   => '9117',
        srange => $ferm_srange,
    }
}
