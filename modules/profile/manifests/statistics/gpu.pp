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

        $packages = [
            'cxlactivitylogger',
            'hcc',
            'hsa-rocr-dev',
            'hsakmt-roct',
            'miopen-hip',
            'miopen-opencl',
            'mivisionx',
            'radeontop',
            'rocblas',
            'rocfft',
            'rocm-cmake',
            'rocm-dev',
            'rocm-device-libs',
            'rocm-opencl',
            'rocm-opencl-dev',
            'rocm-utilsv',
            'rocrand',
        ]

        package { $packages:
            ensure  => 'latest',
            require => [
                Exec['apt_update_rocm'],
                Apt::Repository['amd-rocm'],
            ],
        }

    }

    # Wide range of packages that we deploy across all the stat nodes.
    include ::profile::analytics::cluster::packages::statistics
}