# == Class profile::statistics::gpu
#
class profile::statistics::gpu (
    $hosts_with_gpu = lookup('profile::statistics::gpu::hosts_with_gpu')
) {

    if $::hostname in $hosts_with_gpu {

        # Testing new version - T247082
        if $::hostname == 'stat1008' {
            $rocm_version = '33'
            $rocm_smi_path = '/opt/rocm-3.3.0/bin/rocm-smi'
        } else {
            $rocm_version = '271'
            $rocm_smi_path = '/opt/rocm/bin/rocm-smi'
        }

        class { 'amd_rocm':
            version => $rocm_version,
        }

        class { 'prometheus::node_amd_rocm':
            rocm_smi_path => $rocm_smi_path,
        }
    }
}