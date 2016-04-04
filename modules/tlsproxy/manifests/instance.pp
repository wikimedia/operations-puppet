# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class tlsproxy::instance {
    # Tune kernel settings
    include base::mysterious_sysctl

    $nginx_worker_connections = '32768'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', 'compat')
    $do_spdy = hiera('tlsproxy::localssl::do_spdy', true)

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
