# == Class docker
#
# Install docker on the host, at the desired version. It allows to choose
# whether to install a version from the official debian repositories or
# from dockerproject.org. It also declares the service
#
# === Parameters
#
# [*package_name*] Docker is going through various transitions changing package
# names multiple times already. Support that so we can choose which one we want.
# Defaults to docker.io
#
# On Debian bullseye the 'libapparmor1' package is now installed by default but the
# userspace uilities package 'apparmor' is not.
# This leads to Debian bug #989781 (https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=989781).
# Therefore we need to explicitly install it if on bullseye.
# The good part: actually working apparmor for docker as opposed to previous distro versions.
#
class docker(
    Optional[String] $package_name = undef,
){
    require ::docker::configuration


    # If not set, pick a smart default value for docker packagename.
    if $package_name == undef {
        $_package_name = 'docker.io'
    } else {
        $_package_name = $package_name
    }

    ensure_packages([$_package_name, 'apparmor'])
}
