# == Class docker::packages
#
# Provides docker.io and its dependencies
#
class docker::packages {

  package { [
    'docker.io',
    'aufs-tools',
    'lxc',
    'cgroup-lite',
    ]: ensure => present,
  }

}
