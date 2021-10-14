# == Class: role::prometheus::node_exporter
#
# Role to provision prometheus machine metrics exporter. See also
# https://github.com/prometheus/node_exporter and the module's documentation.
#
# filtertags: labs-project-automation-framework labs-project-graphite

class profile::prometheus::node_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    # We will fix the style break in a later PS
    include prometheus::node_exporter  # lint:ignore:wmf_styleguide


    $_prometheus_nodes = $prometheus_nodes.join(' ')
    $ferm_srange = "(@resolve((${_prometheus_nodes})) @resolve((${_prometheus_nodes}), AAAA))"

    ferm::service { 'prometheus-node-exporter':
        proto  => 'tcp',
        port   => '9100',
        srange => $ferm_srange,
    }
}
