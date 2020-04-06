# == Class profile::statistics::gpu
#
class profile::statistics::gpu {

    $hosts_with_gpu = ['stat1005', 'stat1008']

    if $::hostname in $hosts_with_gpu {

        # Testing new version - T247082
        if $::hostname == 'stat1008' {
            $rocm_version = '33'
        } else {
            $rocm_version = '271'
        }

        class { 'amd_rocm':
            version => $rocm_version,
        }
        class { 'prometheus::node_amd_rocm': }
    }
}