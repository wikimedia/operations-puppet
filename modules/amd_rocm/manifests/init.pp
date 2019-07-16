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
class amd_rocm (
    String $version = '25',
) {

    $supported_versions = ['25']

    if ! ($version in $supported_versions) {
        fail('The version of ROCm requested is not supported or misspelled.')
    }

    if os_version('debian < buster'){
        fail('The class is supported only from Debian Buster onward.')
    }

    # AMD firmwares for GPU cards
    package { 'firmware-amd-graphics':
        ensure => present,
    }

    apt::repository { "amd-rocm${version}":
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "thirdparty/amd-rocm${version}",
        notify     => Exec['apt_update_rocm'],
    }

    exec {'apt_update_rocm':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

    # Note: the miopen-opencl package is imported
    # in the amd-rocm component, but not listed
    # in the packages below for the following reason:
    # Unpacking miopen-opencl (2.0.0-7a8f787) ...
    # [..]
    # trying to overwrite '/opt/rocm/miopen/bin/MIOpenDriver',
    # which is also in package miopen-hip 2.0.0-7a8f787
    $packages = [
        'cxlactivitylogger',
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
    ]

    package { $packages:
        ensure  => 'present',
        require => [
            Exec['apt_update_rocm'],
            Apt::Repository["amd-rocm${version}"],
        ],
    }
}