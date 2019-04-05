# == Class profile::statistics::gpu
#
class profile::statistics::gpu {

    # AMD firmwares for GPU cards
    package { 'firmware-amd-graphics':
        ensure => present,
    }

    # Wide range of packages that we deploy across all the stat nodes.
    include ::profile::analytics::cluster::packages::statistics
}