class profile::docker::registry(
    # The following variables might be useful elsewhere too
    $username = hiera('docker::registry::username'),
    $hash = hiera('docker::registry::hash'),
    # Which machines are allowed to build images.
    $image_builders = hiera('profile::docker::registry::image_builders', undef),
    # cache misc nodes are allowed to connect via HTTP, if defined
    $hnodes = hiera('cache::misc::nodes', {}),
    # Storage configuration
    $storage_backend = hiera('profile::docker::registry::storage_backend', 'filebackend')

) {
    require ::network::constants
    # Hiera configurations
    if !$image_builders {
        $builders = $network::constants::special_hosts[$::realm]['deployment_hosts']
    } else {
        $builders = $image_builders
    }
    $http_allowed_hosts = pick($hnodes[$::site], [])

    if $storage_backend == 'filebackend' {
        include ::profile::docker::registry::filebackend
    }
    else {
        include ::profile::docker::registry::swift
    }

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
        srange => '$DOMAIN_NETWORKS',
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
