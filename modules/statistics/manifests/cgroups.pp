# SPDX-License-Identifier: Apache-2.0
# == Class statistics::cgroups
#
# Enables resource management via cgroups v2 on statistics
# nodes.

class statistics::cgroups (
) {
    Class['::statistics']       -> Class['::statistics::cgroups']
    Class['::statistics::user'] -> Class['::statistics::cgroups']

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
}

