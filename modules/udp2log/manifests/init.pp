# == Class udp2log
#
# Includes packages and setup for udp2log::instances.
# Make sure you include this class if you plan on using
# the udp2log::instance define.
#
# == Parameters
#    $monitor           - If true, monitoring scripts will be installed.
#                         Default: true
#    $default_instance  - If false, remove init script for the default
#                         instance.  Default: true
class udp2log(
    $monitor          = true,
    $default_instance = true
) {
    include contacts::udp2log


    sysctl::parameters { 'big rmem':
        values => {
            'net.core.rmem_max'     => 536870912,
            'net.core.rmem_default' => 4194304,
        },
    }

    # Include the monitoring scripts
    # required for monitoring udp2log instances.
    if $monitor {
        # TODO: Should probably include icincga package here.
        include udp2log::monitoring
    }

    system::role { 'udp2log::logger':
        description => 'udp2log data collection server',
    }

    # make sure the udp2log filter config directory exists
    file { '/etc/udp2log':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    # make sure the udplog package is installed
    require_package('udplog')

    if !$default_instance {
        file { '/etc/init.d/udp2log':
            ensure  => absent,
            require => Package['udplog'],
        }
        exec { '/usr/sbin/update-rc.d -f udp2log remove':
            subscribe   => File['/etc/init.d/udp2log'],
            refreshonly => true,
        }
    }
}
