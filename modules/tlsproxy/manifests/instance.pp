# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class tlsproxy::instance {
    # Tune kernel settings
    include webserver::sysctl_settings

    $nginx_worker_connections = '32768'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', 'compat')

    class { 'nginx': managed => false, }

    file { '/etc/nginx/nginx.conf':
        content => template('tlsproxy/nginx.conf.erb'),
        tag     => 'nginx', # workaround PUP-2689, can remove w/ puppetmaster 3.6.2+
    }

    file { '/etc/logrotate.d/nginx':
        source => 'puppet:///modules/tlsproxy/logrotate',
        tag    => 'nginx', # workaround PUP-2689, can remove w/ puppetmaster 3.6.2+
    }
}

