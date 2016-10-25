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

    if $storage_backend == 'filebackend' {
        $params = {
            'config'   => $config,
            'datapath' => hiera('profile::docker::registry::datapath', '/srv/registry'),
        }
    } else {
        $params = {
            'config'          => $config,
            'storage_backend' => $storage_backend,
            'swift_user'      => hiera('profile::docker::registry::swift_username'),
            'swift_password'  => hiera('profile::docker::registry::swift_password'),
            'swift_url'       => hiera('profile::docker::registry::swift_auth_url'),
            'container'       => hiera('profile::docker::registry::swift_container'),
        }
    }

    create_resources('class', {'::docker::registry' => $params})


    # Nginx frontend
    base::expose_puppet_certs { '/etc/nginx':
        ensure          => present,
        provide_private => true,
        require         => Class['nginx'],
    }

    class { '::sslcert::dhparam': }


    class { '::docker::registry::web':
        docker_username      => $username,
        docker_password_hash => $hash,
        allow_push_from      => $image_builders,
        ssl_settings         => ssl_ciphersuite('nginx', 'mid'),
        use_puppet_certs     => true,
    }

    diamond::collector::nginx{ $::fqdn:
        port => 10080,
    }
}
