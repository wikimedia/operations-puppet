# == Class profile::amd_gpu
#
class profile::amd_gpu (
    $rocm_version = lookup('profile::amd_gpu::rocm_version', { 'default_value' => undef }),
    $kfd_access_group = lookup('profile::amd_gpu::kfd_access_group', { 'default_value' => undef }),
) {

    if $rocm_version {
        if $rocm_version == '33' {
            $rocm_smi_path = '/opt/rocm-3.3.0/bin/rocm-smi'
        } else {
            $rocm_smi_path = '/opt/rocm/bin/rocm-smi'
        }

        class { 'amd_rocm':
            version          => $rocm_version,
            kfd_access_group => $kfd_access_group,
        }

        class { 'prometheus::node_amd_rocm':
            rocm_smi_path => $rocm_smi_path,
        }
    }
}