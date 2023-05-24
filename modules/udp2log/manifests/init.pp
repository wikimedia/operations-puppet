# SPDX-License-Identifier: Apache-2.0
# @summary
# @param monitor          If true, monitoring scripts will be installed.
# @param default_instance If false, remove init script for the default instance.
class udp2log (
    Boolean $monitor          = true,
    Boolean $default_instance = true
) {
    # make sure the udplog package is installed
    ensure_packages(['udplog'])

    # make sure the udp2log filter config directory exists
    file { '/etc/udp2log':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    sysctl::parameters { 'big rmem':
        values => {
            'net.core.rmem_max'     => 536870912,
            'net.core.rmem_default' => 4194304,
        },
    }

    # Include the monitoring scripts
    # required for monitoring udp2log instances.
    class { 'udp2log::monitoring':
        enabled => $monitor,
    }

    unless $default_instance {
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
