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

    if $default_instance {
        systemd::unmask { 'udp2log.service':
            require => Package['udplog'],
        }
    } else {
        systemd::mask { 'udp2log.service':
            require => Package['udplog'],
        }
    }
}
