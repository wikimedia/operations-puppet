# SPDX-License-Identifier: Apache-2.0
# == Class profile::amd_gpu
#
class profile::amd_gpu (
    Optional[String] $rocm_version = lookup('profile::amd_gpu::rocm_version', { 'default_value' => undef }),
    Boolean $is_kubernetes_node = lookup('profile::amd_gpu::is_kubernetes_node', { 'default_value' => false }),
) {
    if $is_kubernetes_node {
        # In most cases, like the stat100x nodes, we are able to control all the users
        # and add them to the 'render' group, needed to access the various devices
        # exposed by ROCm to the OS. In cases like k8s, we delegate the GPU
        # to a device plugin that then exposes the GPU to the Kubelet, and it gets
        # complicated to respect the 'render' posix group access restriction
        # (see https://github.com/RadeonOpenCompute/k8s-device-plugin/issues/39 for
        # more info).
        file { '/etc/udev/rules.d/70-kfd.rules':
            group   => 'root',
            owner   => 'root',
            mode    => '0544',
            content => "SUBSYSTEM==\"kfd\", KERNEL==\"kfd\", MODE=\"0666\"",
        }
        file { '/etc/udev/rules.d/70-render.rules':
            group   => 'root',
            owner   => 'root',
            mode    => '0544',
            content => "SUBSYSTEM==\"drm\", KERNEL==\"renderD*\", MODE=\"0666\"",
        }

        # The GPU device plugin is needed to allow the Kubelet to
        # discover and allocate GPUs to containers.
        package { 'amd-k8s-device-plugin':
            ensure => present,
        }
    }

    if $rocm_version {
        # Some ROCm packages from 3.8+ ship with libpython3.8 requirements,
        # so for the moment we explicitly deploy Python 3.8 on Buster.
        # https://phabricator.wikimedia.org/T275896
        require profile::python38

        class { 'amd_rocm':
            version => $rocm_version,
        }

        class { 'prometheus::node_amd_rocm': }
    }
}
