# = Class: k8s::docker
#
# Sets up docker as used by kubernetes
class k8s::docker {
    apt::repository { 'docker':
        uri        => 'https://apt.dockerproject.org/repo',
        dist       => 'debian-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/k8s/docker.gpg',
    }

    package { 'docker.io':
        ensure  => absent,
        require => Apt::Repository['docker'],
    }

    package { 'docker-engine':
        ensure  => present,
        require => Package['docker.io'],
    }

    $docker_username = hiera('docker::username')
    $docker_password = hiera('docker::password')
    $docker_registry = hiera('docker::registry_url')

    $docker_auth = inline_template("<%= require 'base64'; Base64.encode64('${docker_username}:${docker_password}') %>")

    $docker_config = {
        "${docker_registry}" => {
            'auth' => $docker_auth,
        }
    }

    file { '/root/.dockercfg':
        content => ordered_json($docker_config),
        owner   => 'docker',
        group   => 'docker',
        mode    => '0440',
        notify  => Base::Service_unit['docker'],
    }

    base::service_unit { 'docker':
        systemd   => true,
        subscribe => Package['docker-engine'],
    }
}
