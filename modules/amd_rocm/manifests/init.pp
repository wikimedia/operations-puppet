# SPDX-License-Identifier: Apache-2.0
# == Class amd_rocm
#
# Deploy AMD's ROCm suite and GPU drivers.
# https://rocm.github.io/ROCmInstall.html
#
# == Parameters
#
# [*version*]
#  The ROCm version to deploy in digits without dots.
#  The version corresponds to a component in reprepro,
#  so please check the supported versions before setting it.
#  Default: "42"
#
# [*allow_gpu_broader_access*]
#  Add udev custom rules to allow access to the GPU devices (kfd, renderXXXX)
#  by "others" in order to bypass any group restriction (for example, by the render
#  group). This should be enabled only on nodes without shared/multi-user setup
#  (for example, k8s nodes but not stat100x nodes).
#  Default: false
#
# [*is_kubernetes_node*]
#  Whether or not the host is a kubernetes node.
#  Default: false
#
class amd_rocm (
    String $version = '42',
    Boolean $allow_gpu_broader_access = false,
    Boolean $is_kubernetes_node = false,
) {

    $supported_versions = ['42', '431', '45', '54']

    if ! ($version in $supported_versions) {
        fail('The version of ROCm requested is not supported or misspelled.')
    }

    if debian::codename::ge('bullseye') and ! ($version == '54') {
        fail('Please use ROCm 5.4 with Bullseye, other versions are not supported.')
    }

    # AMD firmware for GPU cards
    if debian::codename::eq('bullseye') {
        # The default firmware-amd-graphics package in bullseye does not have
        # the required firmware files (amdgpu/arcturus_*.bin) for MI100 AMD GPUs.
        apt::package_from_bpo { 'firmware-amd-graphics':
            distro => 'bullseye',
        }
    } else {
        # On buster, we can't install the backport (and that use case is going
        # away anyway), and on Bookworm and later, the standard package has the
        # right files.
        package { 'firmware-amd-graphics':
            ensure => present,
        }
    }

    # In most cases, like the stat100x nodes, we are able to control all the users
    # and add them to the 'render' group, needed to access the various devices
    # exposed by ROCm to the OS. In cases like k8s, we delegate the GPU
    # to a device plugin that then exposes the GPU to the Kubelet, and it gets
    # complicated to respect the 'render' posix group access restriction
    # (see https://github.com/RadeonOpenCompute/k8s-device-plugin/issues/39 for
    # more info).
    if $allow_gpu_broader_access {
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
    }

    if $is_kubernetes_node {
        package { 'amd-k8s-device-plugin':
            ensure => present,
        }
    }

    # rock-dkms quietly skips compiling the kernel module if we don't
    # have the headers for the revelant kernels installed. So before we
    # add the ROCm packages to the machine, install the kernel headers.
    # We don't fold this install into the package list below since we
    # can't rely on apt/dpkg getting the ordering right.
    package{'linux-headers-amd64':
        ensure => present,
    }


    # Note: the miopen-opencl package is imported
    # in the amd-rocm component, but not listed
    # in the packages below for the following reason:
    # Unpacking miopen-opencl (2.0.0-7a8f787) ...
    # [..]
    # trying to overwrite '/opt/rocm/miopen/bin/MIOpenDriver',
    # which is also in package miopen-hip 2.0.0-7a8f787
    $_basepkgs = [
        'hsa-rocr-dev',
        'miopen-hip',
        'mivisionx',
        'radeontop',
        'rccl',
        'rocblas',
        'rocfft',
        'rocm-cmake',
        'rocm-dev',
        'rocm-device-libs',
        'rocm-libs',
        'rocm-opencl',
        'rocm-opencl-dev',
        'rocm-utils',
        'rocrand',
        'rocm-smi-lib',
        'migraphx'
    ]

    # See workarounds outlined in https://github.com/RadeonOpenCompute/ROCm/issues/1125#issuecomment-925362329
    if debian::codename::ge('bullseye') {
        $basepkgs = $_basepkgs + [
          'fake-libgcc-7-dev',
          'fake-libpython3.8',
          'libstdc++-10-dev',
          'libgcc-10-dev'
        ]
    } else {
        $basepkgs = $_basepkgs + [
          'hsakmt-roct'
        ]
    }

    apt::package_from_component { "amd-rocm${version}":
        component => "thirdparty/amd-rocm${version}",
        packages  => $basepkgs,
    }
}
