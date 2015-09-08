# = Class: k8s::docker
#
# Sets up docker as used by kubernetes
class k8s::docker {
    # Use docker from debian backports
    apt::repository { 'debian-backports':
        uri        => 'http://http.debian.net/debian',
        dist       => 'jessie-backports',
        components => 'main',
    }

    package { 'docker.io':
        ensure  => present,
        require => Apt::Repository['debian-backports'],
    }

    base::service_unit { 'docker':
        systemd => true,
    }
}
