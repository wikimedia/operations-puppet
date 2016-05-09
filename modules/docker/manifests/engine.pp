class docker::engine(
    $version = '1.11.1-0~jessie',
    $declare_service = true,
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
        require => Apt::Repository['docker'],
    }

    if $declare_service {
        service { 'docker':
            ensure    => running,
            subscribe => Package['docker-engine'],
        }
    }
}
