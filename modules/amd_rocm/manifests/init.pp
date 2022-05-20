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
# [*kfd_access_group*]
#  Add a udev rule for the kfd device to allow access to users
#  of a specific group. This is usually not needed since the kfd
#  device should be readable by the 'render' group.
#  Default: undef
#
#
class amd_rocm (
    String $version = '42',
    Optional[String] $kfd_access_group = undef,
) {

    $supported_versions = ['42', '431', '45']

    if ! ($version in $supported_versions) {
        fail('The version of ROCm requested is not supported or misspelled.')
    }

    if $kfd_access_group {
        file { '/etc/udev/rules.d/70-kfd.rules':
            group   => 'root',
            owner   => 'root',
            mode    => '0544',
            content => "SUBSYSTEM==\"kfd\", KERNEL==\"kfd\", TAG+=\"uaccess\", GROUP=\"${kfd_access_group}\"",
            require => Group[$kfd_access_group],
        }
    }

    # AMD firmwares for GPU cards
    package { 'firmware-amd-graphics':
        ensure => present,
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
    $basepkgs = [
        'hsakmt-roct',
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

    apt::package_from_component { "amd-rocm${version}":
        component => "thirdparty/amd-rocm${version}",
        packages  => $basepkgs,
    }
}
