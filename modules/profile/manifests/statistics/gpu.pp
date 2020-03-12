# == Class profile::statistics::gpu
#
class profile::statistics::gpu {

    $hosts_with_gpu = ['stat1005', 'stat1008']

    if $::hostname in $hosts_with_gpu {
        class { 'amd_rocm':
            version => '271',
        }

        class { 'prometheus::node_amd_rocm': }
    }
}