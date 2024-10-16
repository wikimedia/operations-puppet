# SPDX-License-Identifier: Apache-2.0
# == Class statistics::cgroups
#
# Enables resource management via cgroups v2 on statistics
# nodes.

class statistics::optimize (
) {
    Class['statistics']       -> Class['statistics::optimize']
    Class['statistics::user'] -> Class['statistics::optimize']

    systemd::override {'total-user-resources.conf':
        source => 'puppet:///modules/statistics/total-user-resources.conf',
        unit   => 'user.slice'
    }
    systemd::override {'individual-user-resources.conf':
        source => 'puppet:///modules/statistics/individual-user-resources.conf',
        # the '-' (hyphen) on the below is significant; see
        # https://www.freedesktop.org/software/systemd/man/latest/
        # user@.service.html#Controlling%20resources%20for%20logged-in%20users
        # for more details
        unit   => 'user-.slice'
    }

    # install and configure zram-based swap (https://en.wikipedia.org/wiki/Zram).
    # This gives much better swap performance without using much RAM, particularly
    # on hosts that lack SSDs.
    package { 'zram-tools':
        ensure => present,
    }
    file {'/etc/default/zramswap':
        source => 'puppet:///modules/statistics/zramswap',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',

    }
    sysctl::parameters { 'zram_swappiness':
        values => {
            # Since we have RAM-based swap, encourage the system to use swap when it's under pressure. See
            # https://facebookmicrosites.github.io/cgroup2/docs/memory-controller.html#using-swap for
            # further justification
            'vm.swappiness' => 30,
        },
    }


}

