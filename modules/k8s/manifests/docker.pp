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
        ensure  => present,
    }

    base::service_unit { 'docker':
        systemd => true,
    }
}
