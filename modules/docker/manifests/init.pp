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
# Defaults to docker-engine on < Buster, docker.io >= Buster (but this is subject to change).
#
# On Debian bullseye the 'libapparmor1' package is now installed by default but the
# userspace uilities package 'apparmor' is not.
# This leads to Debian bug #989781 (https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=989781).
# Therefore we need to explicitly install it if on bullseye.
# The good part: actually working apparmor for docker as opposed to previous distro versions.
#
class docker(
    Optional[String] $version = undef,
    Optional[String] $package_name = undef,
){
    require ::docker::configuration


    # If not set, pick a smart default value for docker packagename.
    if $package_name == undef {
        if debian::codename::lt('buster') {
            $_package_name = 'docker-engine'
        } else {
            $_package_name = 'docker.io'
        }
    } else {
        $_package_name = $package_name
    }


    if debian::codename::lt('buster') {
        package { $_package_name:
            ensure => $version,
        }
    } else {
        ensure_packages([$_package_name, 'apparmor'])
    }
}
