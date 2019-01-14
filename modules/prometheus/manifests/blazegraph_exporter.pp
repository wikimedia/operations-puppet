define prometheus::blazegraph_exporter (
    $blazegraph_port,
    $prometheus_port,
    $prometheus_nodes,
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    systemd::service { "prometheus-blazegraph-exporter-${title}":
        ensure         => present,
        content        => systemd_template('prometheus-blazegraph-exporter'),
        restart        => true,
        require        => File['/usr/local/bin/prometheus-blazegraph-exporter'],
        service_params => {
            ensure => 'running',
        }
    }

    ferm::service { "prometheus-blazegraph-exporter-${title}":
        proto  => 'tcp',
        port   => $prometheus_port,
        srange => $ferm_srange,
    }

    base::service_auto_restart { "prometheus-blazegraph-exporter-${title}": }
}
