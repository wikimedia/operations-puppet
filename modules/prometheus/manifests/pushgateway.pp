class prometheus::pushgateway (
    Wmflib::Ensure       $ensure      = present,
    Stdlib::Port         $listen_port = 9091,
    String               $vhost       = 'prometheus-pushgateway.discovery.wmnet',
    Stdlib::Absolutepath $log_file    = '/var/log/prometheus/pushgateway.log',
) {
    ensure_packages('prometheus-pushgateway')

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

    profile::auto_restarts::service { 'prometheus-pushgateway':
        ensure => $ensure,
    }

    rsyslog::conf { 'prometheus-pushgateway':
        ensure   => $ensure,
        content  => template('prometheus/prometheus-pushgateway.rsyslog.conf.erb'),
        priority => 40,
    }

    logrotate::rule { 'prometheus-pushgateway':
        ensure        => $ensure,
        file_glob     => $log_file,
        frequency     => 'hourly',
        size          => '1G',
        rotate        => 5,
        copy_truncate => true,
        missing_ok    => true,
        no_create     => true,
        compress      => true,
    }
}
