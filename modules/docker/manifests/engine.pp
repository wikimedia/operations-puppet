class docker::engine(
    $version = '1.9.1-0~jessie',
) {
    apt::repository { 'docker':
        uri        => 'https://apt.dockerproject.org/repo',
        dist       => 'debian-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/docker/docker.gpg',
    }

    # Pin a version of docker-engine so we have the same
    # across the fleet
    package { 'docker-engine':
        ensure  => $version,
    }

    $docker_username = hiera('docker::username')
    $docker_password = hiera('docker::password')
    $docker_registry = hiera('docker::registry_url')

    # uses strict_encode64 since encode64 adds newlines?!
    $docker_auth = inline_template("<%= require 'base64'; Base64.strict_encode64('${docker_username}:${docker_password}') -%>")

    $docker_config = {
        'auths' => {
            "${docker_registry}" => {
                'auth' => $docker_auth,
            }
        }
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
        notify  => Base::Service_unit['docker'],
        require => File['/root/.docker'],
    }
}
