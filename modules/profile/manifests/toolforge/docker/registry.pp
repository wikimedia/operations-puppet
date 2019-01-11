class profile::toolforge::docker::registry(
    $user = lookup('docker::username'),
    $hash = lookup('docker::password_hash'),
    $builder_host = lookup('docker::builder_host'),
    $active_node = lookup('profile::toolforge::docker::registry::active_node'),
    $standby_node = lookup('profile::toolforge::docker::registry::standby_node'),
) {
    sslcert::certificate { 'star.tools.wmflabs.org':
        before       => Class['::docker::registry'],
    }

    $builders = [ipresolve($builder_host, 4, $::nameservers[0])]

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

    # make sure we have a backup server ready to take over
    rsync::quickdatacopy { 'docker-registry-sync':
        ensure      => present,
        auto_sync   => true,
        source_host => $active_node,
        dest_host   => $standby_node,
        module_path => '/srv/registry',
    }
}
