# Prometheus Elasticsearch Query Exporter.

class profile::prometheus::es_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes')
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    class { 'prometheus::es_exporter': }

    ferm::service { 'prometheus-es-exporter':
        proto  => 'tcp',
        port   => '9206',
        srange => $ferm_srange,
    }
}
