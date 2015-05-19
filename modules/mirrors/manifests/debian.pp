# Class: mirrors::debian
#
# This class sets up a Debian mirror
#
# Parameters:
#
# Actions:
#       Installs Debian's archiving scripts and runs them periodically
#
# Requires:
#
# Sample Usage:
#   include mirrors::debian

class mirrors::debian {
    require mirrors

    file { '/srv/mirrors/debian':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    # this is <https://ftp-master.debian.org/git/archvsync.git>
    # right now we just ship bin/ftpsync & etc/common; if more are needed in
    # the future this should probably become a git::install resource
    file { "${mirrors::homedir}/archvsync":
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => 'mirror',
        group   => 'mirror',
        mode    => '0755',
        source  => 'puppet:///modules/mirrors/archvsync',
    }

    # don't purge logs (you'd expect more from people that love the FHS...)
    file { "${mirrors::homedir}/archvsync/log":
        ensure => directory,
        purge  => false,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    # this is our configuration for archvsync
    file { "${mirrors::homedir}/archvsync/etc/ftpsync.conf":
        ensure => present,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0555',
        source => 'puppet:///modules/mirrors/ftpsync.conf',
    }

    cron { 'update-debian-mirror':
        ensure  => present,
        command => '/var/lib/mirror/archvsync/bin/ftpsync',
        user    => 'mirror',
        hour    => '*/6',
        minute  => '03',
        require => File['/var/lib/mirror/archvsync/etc/ftpsync.conf'],
    }
}
