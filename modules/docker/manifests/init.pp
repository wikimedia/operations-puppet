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
# [*package_name*] Docker is going through various transitions changing package
# names multiple times already. Support that so we can choose which one we want.
# Defaults to docker-engine currently, but is subject to change
class docker(
    $version,
    $package_name='docker-engine',
){

    if os_version('debian >= stretch') {
        apt::repository { 'thirdparty-k8s':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/k8s',
        }

        package { $package_name:
            ensure  => $version,
            require => [ Apt::Repository['thirdparty-k8s'], Exec['apt-get update']],
        }
    } else {
        package { $package_name:
            ensure => $version,
        }
    }
}
