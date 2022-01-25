define prometheus::blazegraph_exporter (
    $nginx_port,
    $blazegraph_port,
    $prometheus_port,
    $blazegraph_main_ns,
    # collecting via nginx allows using the namespaces alias map used by categories
    # not supported if oauth is activated
    $collect_via_nginx,
) {
    systemd::service { "prometheus-blazegraph-exporter-${title}":
        ensure         => present,
        content        => systemd_template('prometheus-blazegraph-exporter'),
        restart        => true,
        require        => File['/usr/local/bin/prometheus-blazegraph-exporter'],
        service_params => {
            ensure => 'running',
        }
    }
    profile::auto_restarts::service { "prometheus-blazegraph-exporter-${title}": }
}
