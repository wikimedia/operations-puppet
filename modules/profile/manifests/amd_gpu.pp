# SPDX-License-Identifier: Apache-2.0
# == Class profile::amd_gpu
#
class profile::amd_gpu (
    Optional[String] $rocm_version = lookup('profile::amd_gpu::rocm_version', { 'default_value' => undef }),
    Boolean $allow_gpu_broader_access = lookup('profile::amd_gpu::allow_gpu_broader_access', { 'default_value' => false }),
) {

    if $rocm_version {
        $rocm_smi_path = '/opt/rocm/bin/rocm-smi'

        # Some ROCm packages from 3.8+ ship with libpython3.8 requirements,
        # so for the moment we explicitly deploy Python 3.8 on Buster.
        # https://phabricator.wikimedia.org/T275896
        require profile::python38

        class { 'amd_rocm':
            version                  => $rocm_version,
            allow_gpu_broader_access => $allow_gpu_broader_access,
        }

        class { 'prometheus::node_amd_rocm':
            rocm_smi_path => $rocm_smi_path,
        }
    }
}
