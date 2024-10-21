# SPDX-License-Identifier: Apache-2.0
# == Class statistics::optimize
# Performance optimizations for stat hosts

class statistics::optimize (
) {
    Class['statistics']       -> Class['statistics::optimize']
    Class['statistics::user'] -> Class['statistics::optimize']
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

