class profile::elasticsearch::monitoring(
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    class { 'profile::elasticsearch::monitoring::prometheus': }

    ferm::service { 'prometheus_elasticsearch_exporter':
        proto  => 'tcp',
        port   => '9108',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }

}