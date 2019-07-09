# == Class profile::statistics::gpu
#
class profile::statistics::gpu {

    # AMD firmwares for GPU cards
    package { 'firmware-amd-graphics':
        ensure => present,
    }

    if os_version('debian >= buster'){
        apt::repository { 'amd-rocm':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/amd-rocm',
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
        ]

        package { $packages:
            ensure  => 'present',
            require => [
                Exec['apt_update_rocm'],
                Apt::Repository['amd-rocm'],
            ],
        }

    }

    # Wide range of packages that we deploy across all the stat nodes.
    include ::profile::analytics::cluster::packages::statistics
}