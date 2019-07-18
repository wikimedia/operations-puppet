# == Class profile::statistics::gpu
#
class profile::statistics::gpu {

    class { 'amd_rocm':
        version => '26',
    }

    class { 'prometheus::node_amd_rocm': }

    # Wide range of packages that we deploy across all the stat nodes.
    include ::profile::analytics::cluster::packages::statistics
}