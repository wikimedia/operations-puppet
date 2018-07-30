class profile::prometheus::logstash_exporter(
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    class { '::prometheus::logstash_exporter': }

    ferm::service { 'prometheus_logstash_exporter':
        proto  => 'tcp',
        port   => '9198',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }

}
