class docker::registry(
    $datapath = '/srv/registry',
    $allow_push_from,
    $ssl_certificate_name,
    $ssl_settings,
){

    require_package('docker-registry')

    $config = {
        'version' => '0.1',
        'storage' => {
            'filesystem' => {
                'rootdirectory' => $datapath,
            },
            'cache' => {
                'blobdescriptor' => 'inmemory',
            },
        },
        'http'     => {
            'addr' => '127.0.0.1:5000',
            'host' => $::fqdn,
        },
    }

    file { $datapath:
        ensure => directory,
        mode   => '0775',
        owner  => 'docker-registry',
        group  => 'docker-registry',
    }

    # This is by default 0700 for some reason - nothing sensitive inside
    # that doesn't have additional protection
    file { '/etc/docker':
        ensure => directory,
        mode   => '0555',
    }

    $docker_username = hiera('docker::username')
    $docker_password_hash = hiera('docker::password_hash')
    file { '/etc/docker/registry/htpasswd':
        content => "${docker_username}:${docker_password_hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        notify  => Service['docker-registry'],
    }

    file { '/etc/docker/registry/config.yml':
        content => ordered_yaml($config),
        owner   => 'docker-registry',
        group   => 'docker-registry',
        mode    => '0440',
        notify  => Service['docker-registry'],
    }

    # Allow docker-registry to bind to 443 despite not running as root
    exec { 'setcap':
        command   => '/sbin/setcap "cap_net_bind_service=+ep" /usr/bin/docker-registry',
        unless    => '/sbin/setcap -v "cap_net_bind_service=+ep" /usr/bin/docker-registry',
        subscribe => Package['docker-registry'],
        notify    => Service['docker-registry'],
    }

    service { 'docker-registry':
        ensure  => running,
        require => File[
            '/etc/docker',
            '/etc/docker/registry/config.yml'
        ]
    }
    nginx::site { 'registry':
        content => template('docker/registry-nginx.conf.erb'),
    }
}
