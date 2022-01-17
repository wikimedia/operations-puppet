define prometheus::blazegraph_exporter (
    $nginx_port,
    $blazegraph_port,
    $prometheus_port,
    $prometheus_nodes,
    $blazegraph_main_ns,
    # collecting via nginx allows using the namespaces alias map used by categories
    # not supported if oauth is activated
    $collect_via_nginx,
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

    profile::auto_restarts::service { "prometheus-blazegraph-exporter-${title}": }
}
