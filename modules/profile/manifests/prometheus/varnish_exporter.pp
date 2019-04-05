# == Class: profile::prometheus::varnish_exporter
#
# The profile sets up the prometheus exporter for varnish frontend on tcp/9331
#
# === Parameters
# [*nodes*] List of prometheus nodes
#
# filtertags: labs-project-deployment-prep

class profile::prometheus::varnish_exporter(
        $nodes = hiera('prometheus_nodes')
) {
    $prometheus_ferm_nodes = join($nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    prometheus::varnish_exporter{ 'frontend':
        instance       => 'frontend',
        listen_address => ':9331',
    }

    ferm::service { 'prometheus-varnish-exporter-frontend':
        proto  => 'tcp',
        port   => '9331',
        srange => $ferm_srange,
    }
}
