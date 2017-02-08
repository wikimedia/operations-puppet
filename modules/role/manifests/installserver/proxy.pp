# Installs a proxy server for the install server
class role::installserver::proxy {

    if os_version('ubuntu >= trusty') or os_version('debian >= jessie') {
        $config_content = template('role/caching-proxy/squid.conf.erb')
    } else {
        $config_content = template('role/squid3/precise_acls_conf.erb', 'role/caching-proxy/squid.conf.erb')
    }

    class { 'squid3':
        config_content => $config_content,
    }

    cron { 'squid-logrotate':
        ensure  => 'present',
        command => '/usr/sbin/squid3 -k rotate',
        user    => 'root',
        hour    => '17',
        minute  => '15',
    }

    include standard
    include ::base::firewall

    ferm::service { 'proxy':
        proto  => 'tcp',
        port   => '8080',
        srange => '$PRODUCTION_NETWORKS',
    }

    # Monitoring
    monitoring::service { 'squid':
        description   => 'Squid',
        check_command => 'check_tcp!8080',
    }
}
