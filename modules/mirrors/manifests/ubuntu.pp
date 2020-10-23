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

class mirrors::ubuntu {
    require mirrors

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
        source => 'puppet:///modules/mirrors/update-ubuntu-mirror',
    }

    systemd::timer::job { 'update-ubuntu-mirror':
        ensure      => 'present',
        user        => 'root',
        description => 'update the Ubuntu mirror with rsync',
        command     => '/usr/local/sbin/update-ubunut-mirror',
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

}
