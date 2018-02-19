# this adds some WMF specific metrics that are not available in the standard exporter
class profile::prometheus::wmf_elasticsearch_exporter(
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    class { '::prometheus::wmf_elasticsearch_exporter': }

    ferm::service { 'prometheus_wmf_elasticsearch_exporter':
        proto  => 'tcp',
        port   => '9109',
        srange => "(@resolve(${prometheus_nodes_ferm}) @resolve(${prometheus_nodes_ferm}, AAAA))",
    }

}
