# sets up a distribution mirror server

class role::mirror::server {
    system::role { 'role::mirror::server':
        description => 'WMF software mirror server',
    }

    include base::firewall
    include role::installserver::mirrors

    include mirrors::tails


    if os_version('ubuntu >= trusty') or os_version('debian >= jessie') {
        $config_content = template('caching-proxy/squid.conf.erb')
    } else {
        $config_content = template('squid3/precise_acls_conf.erb', 'caching-proxy/squid.conf.erb')
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

    ferm::rule { 'proxy':
        rule => 'proto tcp dport 8080 { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

    include install_server::web_server
    ferm::service { 'http':
        proto => 'tcp',
        port  => 'http'
    }
    ferm::service { 'https':
        proto => 'tcp',
        port  => 'https'
    }

    # Monitoring
    monitoring::service { 'squid':
        description   => 'Squid',
        check_command => 'check_tcp!8080',
    }
    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}

