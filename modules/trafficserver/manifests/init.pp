# == Class: trafficserver
# this class handles common stuff for every trafficserver instance
# === Parameters
#
# [*user*]
#   Run trafficserver as this user (default: 'trafficserver').
# [*packages*]
#   Array of required packages to run trafficserver (default: ['trafficserver', 'trafficserver-experimental-plugins']).
class trafficserver(
  String $user = 'trafficserver',
  Array[String] $packages = ['trafficserver', 'trafficserver-experimental-plugins'],
) {
    ## Packages
    package { $packages:
        ensure  => present,
        require => Exec['apt-get update'],
    }
}
