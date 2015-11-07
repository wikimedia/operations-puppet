# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class tlsproxy::instance(
    $ciphersuite = 'compat'
) {
    # Tune kernel settings
    include webserver::sysctl_settings

    $nginx_worker_connections = '32768'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', $ciphersuite)

    class { 'nginx': managed => false, }

    file { '/etc/nginx/nginx.conf':
        content => template('tlsproxy/nginx.conf.erb'),
        tag     => 'nginx',
    }

    file { '/etc/logrotate.d/nginx':
        source => 'puppet:///modules/tlsproxy/logrotate',
        tag    => 'nginx',
    }
}
