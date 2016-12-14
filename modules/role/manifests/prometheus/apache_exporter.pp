class role::prometheus::apache_exporter {
    prometheus::apache_exporter { 'default': }

    if $::realm == 'labs' {
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_nodes = hiera('prometheus_nodes')
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    }

    ferm::service { 'prometheus-apache_exporter':
        proto  => 'tcp',
        port   => '9117',
        srange => $ferm_srange,
    }
}

