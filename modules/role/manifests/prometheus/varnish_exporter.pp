# == Class: role::prometheus::varnish_exporter
#
# The role sets up one exporter per instance:
#   default on tcp/9131
#   frontend on tcp/9331 (ie. default + 200)
#
# filtertags: labs-project-deployment-prep

class role::prometheus::varnish_exporter {
    if $::realm == 'labs' {
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_nodes = hiera('prometheus_nodes')
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    }

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
