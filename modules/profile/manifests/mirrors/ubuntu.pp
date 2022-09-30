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
    include profile::mirrors

    file { '/srv/mirrors/ubuntu':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    # this is <https://wiki.ubuntu.com/Mirrors/Scripts>
    file { '/usr/local/sbin/update-ubuntu-mirror':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mirrors/update-ubuntu-mirror',
    }

    systemd::timer::job { 'update-ubuntu-mirror':
        ensure      => 'present',
        user        => 'mirror',
        description => 'update the Ubuntu mirror with rsync',
        command     => '/usr/local/sbin/update-ubuntu-mirror',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '6h'},
        require     => File['/usr/local/sbin/update-ubuntu-mirror'],
    }

    # serve via rsync
    rsync::server::module { 'ubuntu':
        path      => '/srv/mirrors/ubuntu/',
        read_only => 'yes',
        uid       => 'nobody',
        gid       => 'nogroup',
    }

    nrpe::monitor_service {'check_ubuntu_mirror':
        description  => 'Ubuntu mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/ubuntu',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mirrors',
    }
}
