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
class docker($version, $use_dockerproject=true){
    if $use_dockerproject {
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
