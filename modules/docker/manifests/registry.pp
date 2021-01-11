class docker::registry(
    Hash $config = {},
    String $storage_backend = 'filebackend',
    Stdlib::Unixpath $datapath = '/srv/registry',
    Optional[String] $swift_user = undef,
    Optional[String] $swift_password = undef,
    Optional[Stdlib::Httpsurl] $swift_url = undef,
    Optional[String] $swift_container = undef,
){

    ensure_packages(['docker-registry'])

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
            $storage_config = {
                'swift'  => {
                    'username'  => $swift_user,
                    'password'  => $swift_password,
                    'authurl'   => $swift_url,
                    'container' => $swift_container,
                },
                'cache' => {
                    'blobdescriptor' => 'inmemory',
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
        # Deep merge so that base settings can be overwritten. Base settings
        # as the first arg so that param provided config can be overridden:
        # * When there is a duplicate key that is a hash, they are recursively
        #   merged.
        # * When there is a duplicate key that is not a hash, the key in the
        #   rightmost hash will "win."
        content => ordered_yaml(deep_merge($base_config, $config)),
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
        ],
    }
}
