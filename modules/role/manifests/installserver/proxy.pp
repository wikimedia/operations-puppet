# Installs a proxy server for the install server
class role::installserver::proxy {
    class { 'squid3':
        config_content => template('role/caching-proxy/squid.conf.erb'),
    }

    cron { 'squid-logrotate':
        ensure  => 'present',
        command => '/usr/sbin/squid3 -k rotate',
        user    => 'root',
        hour    => '17',
        minute  => '15',
    }

    include ::standard
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
