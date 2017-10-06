# == Class: profile::prometheus::varnish_exporter
#
# The profile sets up one exporter per instance:
#   default on tcp/9131
#   frontend on tcp/9331 (ie. default + 200)
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

    prometheus::varnish_exporter{ 'default': }

    ferm::service { 'prometheus-varnish-exporter':
        proto  => 'tcp',
        port   => '9131',
        srange => $ferm_srange,
    }

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
