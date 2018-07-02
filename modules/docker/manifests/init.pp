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
    require ::docker::configuration
    package { $package_name:
        ensure => $version,
    }
}
