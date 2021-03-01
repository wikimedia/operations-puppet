# == Class docker
#
# Install docker on the host, at the desired version. It allows to choose
# whether to install a version from the official debian repositories or
# from dockerproject.org. It also declares the service
#
# === Parameters
#
# [*version*] The package version to install, on Buster and above this is ignored
#             and we simply install the version provided by Debian
#
# [*package_name*] Docker is going through various transitions changing package
# names multiple times already. Support that so we can choose which one we want.
# Defaults to docker-engine currently, but is subject to change
class docker(
    String $version,
    String $package_name='docker-engine',
){
    require ::docker::configuration

    if debian::codename::lt('buster') {
        package { $package_name:
            ensure => $version,
        }
    } else {
        ensure_packages($package_name)
    }
}
