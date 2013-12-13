# Class: install-server::ubuntu-mirror
#
# This class populates ubuntu-mirror's configuration
#
# Parameters:
#
# Actions:
#       Populate ubuntu-mirror configuration directory
#
# Requires:
#
# Sample Usage:
#   include install-server::ubuntu-mirror

class install-server::ubuntu-mirror {
    # Top level directory must exist
    file { '/srv/ubuntu/':
        ensure  => directory,
        owner   => 'mirror',
        group   => 'mirror',
        mode    => '0755',
    }

    # Update script
    file { '/usr/local/sbin/update-ubuntu-mirror':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/install-server/update-ubuntu-mirror',
    }

    # Mirror update cron entry
    cron { 'update-ubuntu-mirror':
        ensure  => present,
        command => '/usr/local/sbin/update-ubuntu-mirror 1>/dev/null 2>/var/lib/mirror/mirror.err.log',
        user    => 'mirror',
        hour    => '*/6',
        minute  => '43',
        require => File['/usr/local/sbin/update-ubuntu-mirror'],
    }
}

