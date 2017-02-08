# filtertags: labs-project-tools
class role::toollabs::docker::builder {
    include ::toollabs::infrastructure

    class { '::profile::docker::storage':
        vg_to_remove     => 'vd',
        physical_volumes => '/dev/vda4',
    }

    class { '::profile::docker::engine':
        settings        => {
            'live-restore' => true,
        },
        version         => '1.12.6-0~debian-jessie',
        declare_service => true,
        require         => Class['::profile::docker::storage'],
    }

    class { '::toollabs::images': }

    # This requires push privilages
    $docker_username = hiera('docker::username')
    $docker_password = hiera('docker::password')
    $docker_registry = hiera('docker::registry')

    # uses strict_encode64 since encode64 adds newlines?!
    $docker_auth = inline_template("<%= require 'base64'; Base64.strict_encode64('${docker_username}:${docker_password}') -%>")

    $docker_config = {
        'auths' => {
            "${docker_registry}" => {
                'auth' => $docker_auth,
            },
        },
    }

    file { '/root/.docker':
        ensure => directory,
        owner  => 'root',
        group  => 'docker',
        mode   => '0550',
    }

    file { '/root/.docker/config.json':
        content => ordered_json($docker_config),
        owner   => 'root',
        group   => 'docker',
        mode    => '0440',
        notify  => Service['docker'],
        require => File['/root/.docker'],
    }
}
