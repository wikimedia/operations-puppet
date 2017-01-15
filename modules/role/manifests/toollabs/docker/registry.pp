# filtertags: labs-project-tools
class role::toollabs::docker::registry {
    include ::toollabs::infrastructure

    require ::role::labs::lvm::srv

    sslcert::certificate { 'star.tools.wmflabs.org':
        before       => Class['::docker::registry'],
    }

    $builders = [ipresolve(hiera('docker::builder_host'), 4, $::nameservers[0])]

    $user = hiera('docker::username')
    $hash = hiera('docker::password_hash')

    class { '::docker::registry':
        storage_backend => 'filebackend',
        datapath        => '/srv/registry',
    }

    class { '::docker::registry::web':
        docker_username      => $user,
        docker_password_hash => $hash,
        allow_push_from      => $builders,
        ssl_certificate_name => 'star.tools.wmflabs.org',
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
    }
}
