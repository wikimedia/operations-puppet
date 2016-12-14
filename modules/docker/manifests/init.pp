# == Class docker
#
# Install docker on the host, at the desired version. It allows to choose
# whether to install a version from the official debian repositories or
# from dockerproject.org. It also declares the service
#
# === Parameters
#
# [*version*] The package version to install
#
# [*use_dockerproject*] Whether to use dockerproject.org packages or not.
#
# [*proxy*] If given, it will allow to use a proxy to dockerproject.org
#
class docker($version, $use_dockerproject=true, $proxy=undef){
    if $use_dockerproject {
        apt::repository { 'docker':
            ensure     => absent,
            uri        => 'https://apt.dockerproject.org/repo',
            dist       => 'debian-jessie',
            components => 'main',
            source     => false,
        }

        file { '/var/lib/apt/keys/docker.gpg':
            ensure => absent,
        }

        exec { '/usr/bin/apt-key del 2C52609D':
            subscribe   => File['/var/lib/apt/keys/docker.gpg'],
            refreshonly => true,
        }

        apt::conf { 'dockerproject-org-proxy':
            ensure   => absent,
            priority => '80',
            key      => 'Acquire::http::Proxy::apt.dockerproject.org',
            value    => $proxy,
        }
        $package = 'docker-engine'
        $absent_package = 'docker.io'
    }
    else {
        $package = 'docker.io'
        $absent_package = 'docker-engine'
    }

    package { $absent_package:
        ensure => absent,
    }
    package { $package:
        ensure => $version,
    }
}
