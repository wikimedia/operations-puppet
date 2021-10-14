# == Class: role::prometheus::node_exporter
#
# Role to provision prometheus machine metrics exporter. See also
# https://github.com/prometheus/node_exporter and the module's documentation.
#
# filtertags: labs-project-automation-framework labs-project-graphite

class profile::prometheus::node_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    class { 'prometheus::node_exporter': }

    $_prometheus_nodes = $prometheus_nodes.join(' ')
    $ferm_srange = "(@resolve((${_prometheus_nodes})) @resolve((${_prometheus_nodes}), AAAA))"

    ferm::service { 'prometheus-node-exporter':
        proto  => 'tcp',
        port   => '9100',
        srange => $ferm_srange,
    }
}
