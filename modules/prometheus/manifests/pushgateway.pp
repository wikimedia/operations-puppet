class prometheus::pushgateway (
    Wmflib::Ensure $ensure = present,
    Stdlib::Port   $listen_port = 9091,
    String         $vhost = 'prometheus-pushgateway.discovery.wmnet',
) {
    require_package('prometheus-pushgateway')

    httpd::site{ 'pushgateway':
        priority => 30, # Earlier than main prometheus* vhost wildcard matching
        content  => template('prometheus/pushgateway-apache.erb'),
    }

    systemd::service { 'prometheus-pushgateway':
        ensure         => $ensure,
        restart        => true,
        content        => systemd_template('prometheus-pushgateway'),
        service_params => {
            hasrestart => true,
        },
    }
}
