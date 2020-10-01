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
#  Default: "25"
#
# [*kfd_access_group*]
#  Add a udev rule for the kfd device to allow access to users
#  of a specific group. This is usually not needed since the kfd
#  device should be readable by the 'render' group.
#  Default: undef
#
#
class amd_rocm (
    String $version = '33',
    Optional[String] $kfd_access_group = undef,
) {

    $supported_versions = ['25', '26', '271', '33']

    if ! ($version in $supported_versions) {
        fail('The version of ROCm requested is not supported or misspelled.')
    }

    if $kfd_access_group {
        file { '/etc/udev/rules.d/70-kfd.rules':
            owner   => 'root',
            group   => 'root',
            mode    => '0544',
            content => "SUBSYSTEM==\"kfd\", KERNEL==\"kfd\", TAG+=\"uaccess\", GROUP=\"${kfd_access_group}\"",
            require => Group[$kfd_access_group],
        }
    }

    # AMD firmwares for GPU cards
    package { 'firmware-amd-graphics':
        ensure => present,
    }

    # Note: the miopen-opencl package is imported
    # in the amd-rocm component, but not listed
    # in the packages below for the following reason:
    # Unpacking miopen-opencl (2.0.0-7a8f787) ...
    # [..]
    # trying to overwrite '/opt/rocm/miopen/bin/MIOpenDriver',
    # which is also in package miopen-hip 2.0.0-7a8f787
    $packages = [
        'hcc',
        'hsa-rocr-dev',
        'hsakmt-roct',
        'miopen-hip',
        'mivisionx',
        'radeontop',
        'rocblas',
        'rocfft',
        'rocm-cmake',
        'rocm-dev',
        'rocm-device-libs',
        'rocm-opencl',
        'rocm-opencl-dev',
        'rocm-utils',
        'rocrand',
        'rocm-smi',
        'rccl',
        'rocm-libs',
        'rock-dkms',
    ]

    apt::package_from_component { "amd-rocm${version}":
        component => "thirdparty/amd-rocm${version}",
        packages  => $packages,
    }
}
