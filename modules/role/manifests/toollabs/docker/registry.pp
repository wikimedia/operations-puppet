class role::toollabs::docker::registry {
    include ::toollabs::infrastructure

    require role::labs::lvm::srv

    sslcert::certificate { 'star.tools.wmflabs.org':
        before       => Class['::docker::registry'],
    }

    $builder = ipresolve(hiera('docker::builder_host'), 4, $::nameservers[0])

    $user = hiera('docker::username')
    $hash = hiera('docker::password_hash')

    class { '::docker::registry':
        docker_username      => $user,
        docker_password_hash => $hash,
        backend              => 'filebackend',
        datapath             => '/srv/registry',
        allow_push_from      => $builder,
        ssl_certificate_name => 'star.tools.wmflabs.org',
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
    }
}
