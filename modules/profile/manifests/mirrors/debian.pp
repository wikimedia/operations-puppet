# SPDX-License-Identifier: Apache-2.0
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

class profile::mirrors::debian {
    require profile::mirrors
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

    # package doesn't ship that directory yet
    file { '/etc/ftpsync':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0555',
    }

    # this is our configuration for archvsync
    file { '/etc/ftpsync/ftpsync.conf':
        ensure  => present,
        owner   => 'mirror',
        group   => 'mirror',
        mode    => '0444',
        content => template('profile/mirrors/ftpsync.conf.erb'),
    }

    file { '/var/log/ftpsync':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    # allow the Debian syncproxy to trigger ftpsync runs over ssh
    ssh::userkey { 'mirror':
        ensure => absent,
    }

    # serve via rsync
    rsync::server::module { 'debian':
        ensure    => absent,
        path      => '/srv/mirrors/debian/',
        read_only => 'yes',
        uid       => 'nobody',
        gid       => 'nogroup',
    }

    nrpe::monitor_service {'check_debian_mirror':
        ensure         => absent,
        description    => 'Debian mirror in sync with upstream',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/debian',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mirrors',
        migration_task => 'T367149',
    }
}
