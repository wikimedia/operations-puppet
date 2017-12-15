class profile::prometheus::elasticsearch_exporter(
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    class { '::prometheus::elasticsearch_exporter': }

    ferm::service { 'prometheus_elasticsearch_exporter':
        proto  => 'tcp',
        port   => '9108',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }

}
