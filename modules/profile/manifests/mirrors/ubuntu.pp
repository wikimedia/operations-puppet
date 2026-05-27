# SPDX-License-Identifier: Apache-2.0
# Class: mirrors::ubuntu
#
# This class sets up an Ubuntu mirror
#
# Parameters:
#
# Actions:
#       Populate Ubuntu mirror configuration directory
#
# Requires:
#
# Sample Usage:
#   include mirrors::ubuntu

class profile::mirrors::ubuntu {
    file { '/srv/mirrors/ubuntu':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    # this is <https://wiki.ubuntu.com/Mirrors/Scripts>
    file { '/usr/local/sbin/update-ubuntu-mirror':
        ensure => absent,
    }

    systemd::timer::job { 'update-ubuntu-mirror':
        ensure      => absent
    }

    # serve via rsync
    rsync::server::module { 'ubuntu':
        ensure => absent,
    }
}
