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
    }
    else {
        $swift_accounts = hiera('swift::params::accounts')
        $swift_account = $swift_accounts['docker_registry']
        $swift_account_keys = hiera('swift::params::account_keys')
        $swift_container = hiera(
            'profile::docker::registry::swift_container',
            'docker_registry'
        )
        $swift_auth_url = hiera('profile::docker::registry::swift_auth_url')
        $params = {
            'config'          => $config,
            'storage_backend' => $storage_backend,
            'swift_user'      => $swift_account['user'],
            'swift_password'  => $swift_account_keys['docker_registry'],
            'swift_url'       => 'http://swift.svc.codfw.wmnet/auth/v1.0',
            'swift_container' => $swift_container,
        }
    }

    create_resources('class', {'::docker::registry' => $params})


    # Nginx frontend
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
