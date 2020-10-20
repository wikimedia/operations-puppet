class prometheus::pushgateway (
    Wmflib::Ensure $ensure = present,
    Stdlib::Port   $listen_port = 9091,
) {
    require_package('prometheus-pushgateway')

    systemd::service { 'prometheus-pushgateway':
        ensure         => $ensure,
        restart        => true,
        content        => systemd_template('prometheus-pushgateway'),
        service_params => {
            hasrestart => true,
        },
    }
}
