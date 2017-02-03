# == Class: role::prometheus::node_exporter
#
# Role to provision prometheus machine metrics exporter. See also
# https://github.com/prometheus/node_exporter and the module's documentation.
#
# filtertags: labs-project-automation-framework labs-project-graphite

class role::prometheus::node_exporter {
    include ::prometheus::node_exporter

    if $::realm == 'labs' {
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_nodes = hiera('prometheus_nodes')
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    }

    ferm::service { 'prometheus-node-exporter':
        proto  => 'tcp',
        port   => '9100',
        srange => $ferm_srange,
    }
}
