# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class tlsproxy::instance {
    # Tune kernel settings
    include base::mysterious_sysctl

    $keepalives_per_worker = hiera('tlsproxy::localssl::keepalives_per_worker', 0)
    $websocket_support = hiera('cache::websocket_support', false)
    $nginx_worker_connections = '32768'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', 'compat')
    $nginx_tune_for_media = hiera('cache::tune_for_media', false)

    class { 'nginx': managed => false, }

    file { '/etc/nginx/nginx.conf':
        content => template('tlsproxy/nginx.conf.erb'),
        tag     => 'nginx',
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/tlsproxy/logrotate',
        tag    => 'nginx',
    }

    # systemd unit fragment for additional security restrictions:
    $sysd_sec_dir = '/etc/systemd/system/nginx.service.d'
    $sysd_sec_conf = "${sysd_sec_dir}/security.conf"

    file { $sysd_sec_dir:
        ensure => directory,
        mode   => '0555',
        owner  => root,
        group  => root,
    }

    file { $sysd_sec_conf:
        ensure  => present,
        mode    => '0444',
        owner   => root,
        group   => root,
        source  => 'puppet:///modules/tlsproxy/nginx-security.conf',
        before  => Class['nginx'],
        require => File[$sysd_sec_dir],
    }

    exec { "systemd reload for ${sysd_sec_conf}":
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => File[$sysd_sec_conf],
    }
}
