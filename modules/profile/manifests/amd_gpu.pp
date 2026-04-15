# SPDX-License-Identifier: Apache-2.0
# == Class profile::amd_gpu
#
class profile::amd_gpu (
    Optional[String] $rocm_version = lookup('profile::amd_gpu::rocm_version', { 'default_value' => undef }),
    Boolean $is_kubernetes_node = lookup('profile::amd_gpu::is_kubernetes_node', { 'default_value' => false }),
    Boolean $is_basic_gpu_node = lookup('profile::amd_gpu::is_basic_gpu_node', { 'default_value' => false }),
    Boolean $firmwares_from_bpo = lookup('profile::amd_gpu::firmwares_from_bpo', { 'default_value' => false }),
    Boolean $enable_opt_rocm_env = lookup('profile::amd_gpu::enable_opt_rocm_env', { 'default_value' => false }),
    Boolean $use_rocm_amd_smi = lookup('profile::amd_gpu::use_rocm_amd_smi', { 'default_value' => false }),
    Optional[String] $kubernetes_cluster_name = lookup('profile::kubernetes::cluster_name', { 'default_value' => undef }),
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
        # On bookworm we use libhwloc15 from bpo to better support
        # more recent versions of the GPU plugin.
        if debian::codename::eq('bookworm') {
            apt::package_from_bpo { 'libhwloc15-bookworm-bpo':
                packages => {
                    'libhwloc15' => '2.12.0-4~bpo12+1',
                },
                distro   => 'bookworm',
            }
        }
        package { 'amd-k8s-device-plugin':
            ensure => present,
        }

        systemd::override { 'amd-devplugin-after-labeller':
            ensure  => present,
            unit    => 'amd-k8s-node-labeller',
            restart => true,
            content => "[Unit]\nAfter=amd-k8s-device-plugin.service\nRequires=amd-k8s-device-plugin.service\n",
        }

        file { '/etc/amd':
            ensure => 'directory',
        }
        $k8s_config = k8s::fetch_cluster_config($kubernetes_cluster_name)
        $amd_node_labeller_username = 'amdgpu-node-labeller'
        $amd_node_labeller_client_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], $amd_node_labeller_username, {
            'renew_seconds'  => $k8s_config['pki_renew_seconds'],
            'outdir'         => '/etc/kubernetes/pki',
            'owner'           => 'amd-nodelabeller',
            'group'           => 'amd-nodelabeller',
        })
        k8s::kubeconfig { '/etc/amd/node-labeller-kubeconfig':
            owner       => 'amd-nodelabeller',
            group       => 'amd-nodelabeller',
            master_host => $k8s_config['master'],
            username    => $amd_node_labeller_username,
            auth_cert   => $amd_node_labeller_client_cert,
            require     => File['/etc/amd'],
        }

        package { 'amd-k8s-node-labeller':
            ensure  => present,
            require => K8s::Kubeconfig['/etc/amd/node-labeller-kubeconfig'],
        }
    }

    if $is_basic_gpu_node or $is_kubernetes_node or $rocm_version {
        # GPUs like MI300X require an up-to-date amd-smi-lib package
        # to be able to perform tasks like GPU partitioning.
        # More info: T403697
        if debian::codename::eq('trixie')  {
            if $use_rocm_amd_smi {
                apt::package_from_component { 'amd-smi-rocm702':
                    component => 'thirdparty/amd-rocm702',
                    packages  => ['rocm-core', 'amd-smi-lib'],
                }
                ensure_packages(['libdrm-amdgpu1'])
                $rocm_smi_path = '/opt/rocm/bin/amd-smi'

                # Hack needed to make amd-smi running without
                # errors/warnings on ROCm 7.0.2
                # https://phabricator.wikimedia.org/T403697#11303725
                file { '/usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so':
                    ensure => 'link',
                    target => '/usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1',
                }
            } else {
                ensure_packages(['rocm-smi'])
                $rocm_smi_path = '/usr/bin/rocm-smi'
            }
            # Experiment for using direct GPU-GPU communication instead of shm.
            # More info in T421461
            grub::bootparam { 'iommu':
                value => 'pt',
            }
        } elsif debian::codename::eq('bookworm') {
            ensure_packages(['rocm-smi'])
            $rocm_smi_path = '/usr/bin/rocm-smi'
        } elsif debian::codename::eq('bullseye') {
            $rocm_smi_path = '/opt/rocm/bin/rocm-smi'
        } else {
            fail('The AMD smi tool is not configured for this OS.')
        }

        class { 'prometheus::node_amd_rocm':
            rocm_smi_path => $rocm_smi_path,
        }

        if $firmwares_from_bpo {
            if debian::codename::eq('bookworm') {
                apt::package_from_bpo { 'firmware-amd-graphics-bookworm-bpo':
                    packages => {
                        'firmware-amd-graphics' => '20250410-2~bpo12+1',
                    },
                    distro   => 'bookworm',
                }
            } elsif debian::codename::eq('trixie') {
                apt::package_from_bpo { 'firmware-amd-graphics-trixie-bpo':
                    packages => {
                        'firmware-amd-graphics' => '20251021-1~bpo13+1',
                    },
                    distro   => 'trixie',
                }
            } else {
                fail('AMD GPU firmwares from BPO not available on this OS.')
            }
        } elsif debian::codename::eq('bullseye') {
              # The default firmware-amd-graphics package in bullseye does not have
              # the required firmware files (amdgpu/arcturus_*.bin) for MI100 AMD GPUs.
              apt::package_from_component { 'amd-gpu-firmware':
                  component => 'component/amd-gpu-firmware',
                  packages  => ['firmware-amd-graphics'],
              }
        } else {
            ensure_packages('firmware-amd-graphics')
        }
    }

    if $rocm_version {
        class { 'amd_rocm':
            version => $rocm_version,
        }
    }

    if $enable_opt_rocm_env {
        systemd::environment { 'opt_rocm':
            variables => {
                # Install a PATH component for /opt/rocm/bin
                'PATH' => '$PATH:/opt/rocm/bin',
            },
        }
    }
}
