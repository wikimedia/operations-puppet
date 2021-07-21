class profile::toolforge::docker::image_builder(
    String       $docker_username = lookup('docker::username'),
    String       $docker_password = lookup('docker::password'),
    Stdlib::Fqdn $docker_registry = lookup('docker::registry'),
    String $component = lookup('profile::wmcs::kubeadm::component', {default_value => 'thirdparty/kubeadm-k8s-1-18'}),
) {
    # This should be building with the same docker we are running
    class { '::kubeadm::repo':
        component => $component,
    }

    labs_lvm::volume { 'docker':
        size      => '70%FREE',
        mountat   => '/var/lib/docker',
        mountmode => '711',
    } -> class {'profile::labs::lvm::srv': }

    class { '::kubeadm::docker': }

    class { '::docker::baseimages':
        docker_registry => $docker_registry,
    }

    git::clone { 'operations/docker-images/toollabs-images':
        ensure    => present,
        directory => '/srv/images/toolforge',
    }

    git::clone { 'cloud/toolforge/buildpacks':
        ensure    => present,
        directory => '/srv/buildpacks',
    }

    # Available in Toolforge's aptly repo
    ensure_packages(['pack'])

    # Registry credentials require push privilages
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
        group  => 'root',
        mode   => '0550',
    }

    file { '/root/.docker/config.json':
        content => ordered_json($docker_config),
        owner   => 'root',
        group   => 'docker',
        mode    => '0440',
        require => File['/root/.docker'],
    }
}
