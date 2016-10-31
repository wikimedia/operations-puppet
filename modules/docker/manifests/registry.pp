class docker::registry(
    $config={},
    $storage_backend='filebackend',
    $datapath='/srv/registry',
    $swift_user=undef,
    $swift_password=undef,
    $swift_url=undef,
    $swift_container=undef,
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


    $base_config = {
        'version' => '0.1',
        'storage' => $storage_config,
        'http'     => {
            'addr' => '127.0.0.1:5000',
        },
    }

    # This is by default 0700 for some reason - nothing sensitive inside
    # that doesn't have additional protection
    file { '/etc/docker':
        ensure => directory,
        mode   => '0555',
    }


    file { '/etc/docker/registry/config.yml':
        content => ordered_yaml(merge($config, $base_config)),
        owner   => 'docker-registry',
        group   => 'docker-registry',
        mode    => '0440',
        notify  => Service['docker-registry'],
    }

    service { 'docker-registry':
        ensure  => running,
        require => File[
            '/etc/docker',
            '/etc/docker/registry/config.yml'
        ]
    }
}
