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

    package { 'ftpsync':
        ensure => present,
    }

    # this is our configuration for archvsync
    file { '/etc/ftpsync':
        ensure  => present,
        owner   => 'mirror',
        group   => 'mirror',
        mode    => '0555',
        content => template('mirrors/ftpsync.conf.erb'),
    }

    file { '/var/log/ftpsync':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
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
