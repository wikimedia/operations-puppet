class docker::registry(
    $allow_push_from,
    $ssl_certificate_name,
    $ssl_settings,
    $storage_backend='filebackend',
    $datapath='/srv/registry',
    $swift_user=undef,
    $swift_password=undef,
    $swift_url=undef,
    $swift_contasiner=undef,
){

    require_package('docker-registry')

    case $storage_backend {
        'filebackend': {
            $storage_config = {
                'filesystem' => { 'rootdirectory' => $datapath },
                'cache'      => { 'blobdescriptor' => 'inmemory' },
            }
            file { $datapath:
                ensure => directory,
                mode   => '0775',
                owner  => 'docker-registry',
                group  => 'docker-registry',
            }
        }
        'swift': {
            $username = hiera('profile::docker::registry::swift_username')
            $password = hiera('profile::docker::registry::swift_password')
            $auth_url = hiera('profile::docker::registry::swift_auth_url')
            $container = hiera('profile::docker::registry::swift_container')
            $storage_config = {
                'swift'  => {
                    'username'  => $username,
                    'password'  => $password,
                    'authurl'   => $auth_url,
                    'container' => $container,
                },
                'cache' => {
                    'blobdescriptor' => 'inmemory'
                },
            }
        }
        default: { fail("Unsupported storage backend ${storage_backend}") }
    }


    $config = {
        'version' => '0.1',
        'storage' => $storage_config,
        'http'     => {
            'addr' => '127.0.0.1:5000',
            'host' => $::fqdn,
        },
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
