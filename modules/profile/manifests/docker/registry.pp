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

    # cache misc nodes are allowed to connect via HTTP, if defined
    $hnodes = hiera('cache::misc::nodes', {})
    $http_allowed_hosts = pick($hnodes[$::site], [])

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
        $swift_auth_url = hiera('profile::docker::registry::swift_auth_url')
        # By default, the password will be extracted from swift, but can be overridden
        $swift_account_keys = hiera('swift::params::account_keys')
        $swift_container = hiera(
            'profile::docker::registry::swift_container',
            'docker_registry'
        )
        $swift_password = hiera('profile::docker::registry::swift_password', $swift_account_keys['docker_registry'])
        $params = {
            'config'          => $config,
            'storage_backend' => $storage_backend,
            'swift_user'      => $swift_account['user'],
            'swift_password'  => $swift_password,
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
        http_endpoint        => true,
        http_allowed_hosts   => $http_allowed_hosts,
    }

    diamond::collector::nginx{ $::fqdn:
        port => 10080,
    }

    ferm::service { 'docker_registry_https':
        proto  => 'tcp',
        port   => 'https',
        srange => '$DOMAIN_NETWORKS',
    }

    ferm::service { 'docker_registry_http_81':
        proto  => 'tcp',
        port   => '81',
        srange => '$CACHE_MISC',
    }

    # Monitoring
    # HTTP should return 403 forbidden
    monitoring::service { 'check_docker_registry_http':
        description   => 'Docker registry HTTP interface',
        check_command => 'check_http_port_status!81!403',
    }
    # This will test both nginx and the docker registry application
    monitoring::service { 'check_docker_registry_https':
        description   => 'Docker registry HTTPS interface',
        check_command => "check_https_url_for_string!${::fqdn}!/v2/wikimedia-jessie/manifests/latest!schemaVersion",
    }

    nrpe::monitor_systemd_unit_state{ 'docker-registry': }

}
