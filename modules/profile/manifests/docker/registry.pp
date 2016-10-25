class profile::docker::registry {
    require ::network::constants
    # Hiera configurations
    # The following variables might be useful elsewhere too
    $username = hiera('docker::registry::username')
    $hash = hiera('docker::registry::hash')
    # Which machines are allowed to build images
    $image_builders = hiera(
        'profile::docker::registry::image_builders',
        $network::constants::special_hosts[$::realm]['deployment_hosts'])
    $config = hiera('profile::docker::registry::config', {})

    # Storage configuration
    $storage_backend = hiera('profile::docker::registry::storage_backend', 'filebackend')

    case $storage_backend {
        'filebackend': {
            $data_path = hiera('profile::docker::registry::datapath', '/srv/registry')
            $storage_config = {
                'storage' => {
                    'filesystem' => { 'rootdirectory' => $data_path },
                    'cache'      => { 'blobdescriptor' => 'inmemory' },

                }
            }
            file { $data_path:
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
                'storage' => {
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
        }
        default: { fail("Unsupported storage backend ${storage_backend}") }
    }

    # TODO: once done with testing/migrating, this should all go in docker::registry
    # Configuration
    $default_config = {
        'version' => '0.1',
        'http' => {
            'addr' => '127.0.0.1:5000',
        }
    }
    $registry_config = merge($default_config, $config, $storage_config)

    file { '/etc/docker/registry/config.yml':
        content => ordered_yaml($registry_config),
        owner   => 'docker-registry',
        group   => 'docker-registry',
        mode    => '0440',
        notify  => Service['docker-registry'],
    }



    # Package and service installation
    require_package('docker-registry')

    service { 'docker-registry':
        ensure    => running,
        subscribe => File[
            '/etc/docker/registry/config.yml',
        ]
    }

    # Nginx frontend
    base::expose_puppet_certs { '/etc/nginx':
        ensure          => present,
        provide_private => true,
        require         => Class['nginx'],
    }

    class { '::sslcert::dhparam': }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid')

    file { '/etc/nginx/registry.htpasswd':
        content => "${username}:${hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
    }

    nginx::site { 'registry':
        ensure  => present,
        content => template('profile/docker/registry-nginx.conf.erb'),
    }

    diamond::collector::nginx{ $::fqdn:
        port => 10080,
    }
}
