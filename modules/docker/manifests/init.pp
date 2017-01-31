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
# [*use_docker_io_repo*] Use upstream's docker repo directly
class docker(
    $version,
    $use_dockerproject=true,
    $use_docker_io_repo=false
){
    if $use_dockerproject {
        $package = 'docker-engine'
        $absent_package = 'docker.io'

        if $use_docker_io_repo {
            apt::repository { 'docker':
                uri        => 'https://apt.dockerproject.org/repo',
                dist       => 'debian-jessie',
                components => 'main',
                source     => false,
                keyfile    => 'puppet:///modules/docker/docker.gpg',
            }
        }
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
