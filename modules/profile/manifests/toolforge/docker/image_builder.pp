class profile::toolforge::docker::image_builder(
    String       $docker_username = lookup('docker::username'),
    String       $docker_password = lookup('docker::password'),
    Stdlib::Fqdn $docker_registry = lookup('docker::registry'),
    String       $component       = lookup('profile::wmcs::kubeadm::component'),
) {
    include profile::docker::engine
    cinderutils::ensure { 'separate-docker':
        min_gb        => 10,
        mount_point   => '/var/lib/docker',
        mount_mode    => '711',
        mount_options => 'discard,defaults',
        notify        => Service['docker'],
    }

    file { '/srv/images':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'operations/docker-images/toollabs-images':
        ensure    => present,
        directory => '/srv/images/toolforge',
    }

    # Registry credentials require push privileges
    docker::credentials { '/root/.docker/config.json':
        owner             => 'root',
        group             => 'docker',
        registry          => $docker_registry,
        registry_username => $docker_username,
        registry_password => $docker_password,
    }
}
