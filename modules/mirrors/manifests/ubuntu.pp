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

    cron { 'update-ubuntu-mirror':
        ensure  => present,
        command => '/usr/local/sbin/update-ubuntu-mirror 1>/dev/null 2>/var/lib/mirror/mirror.err.log',
        user    => 'mirror',
        hour    => '*/3',
        minute  => '43',
        require => File['/usr/local/sbin/update-ubuntu-mirror'],
    }
}
