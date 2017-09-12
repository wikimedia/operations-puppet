# == Class contint::docker
#
# Install download.docker.com list and public key. Install docker-ce.
#
class contint::docker {
    apt::repository { 'download.docker.com':
        uri        => 'https://download.docker.com/linux/debian',
        dist       => $::lsbdistcodename,
        components => 'stable',
        source     => false,
        keyfile    => 'puppet:///modules/contint/download.docker.com.gpg',
    }

    package { [
        'docker',
        'docker-engine',
        'docker.io'
    ]:
        ensure => absent,
    }

    package{ 'docker-ce':
        require => Apt::Repository['download.docker.com'],
    }
}
