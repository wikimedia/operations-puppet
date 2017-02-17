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
    include passwords::mirrors

    file { '/srv/mirrors/debian':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    # this is <https://ftp-master.debian.org/git/archvsync.git>
    # right now we just ship bin/ftpsync & bin/common
    # there is soon going to be a Debian package, use that then instead
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

    # move to .config/archvsync or /etc/archvsync?
    file { "${mirrors::homedir}/archvsync/etc":
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    # this is our configuration for archvsync
    file { "${mirrors::homedir}/archvsync/etc/ftpsync.conf":
        ensure  => present,
        owner   => 'mirror',
        group   => 'mirror',
        mode    => '0555',
        content => template('mirrors/ftpsync.conf.erb'),
    }

    # allow the Debian syncproxy to trigger ftpsync runs over ssh
    ssh::userkey { 'mirror':
        source => 'puppet:///modules/mirrors/ssh-debian-archvsync.pub',
    }

    # serve via rsync
    rsync::server::module { 'debian':
        path      => '/srv/mirrors/debian/',
        read_only => 'yes',
        uid       => 'nobody',
        gid       => 'nogroup',
    }

}
