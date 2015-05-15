# Class: install-server::tftp-server
#
# This class installs and configures atftpd
#
# Parameters:
#
# Actions:
#   Install and configure atftpd and populate tftp directory structures
#
# Requires:
#
# Sample Usage:
#   include install-server::tftp-server

class install-server::tftp-server {
    file { '/srv/tftpboot':
        # config files in the puppet repository,
        # larger files like binary images in volatile
        source       => [
            'puppet:///modules/install-server/tftpboot',
            'puppet:///volatile/tftpboot'
        ],
        sourceselect => all,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        recurse      => remote,
        backup       => false,
    }

    file { '/etc/default/atftpd':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/install-server/atftpd-default',
        notify => Service['atftpd'],
    }

    package { 'atftpd':
        ensure  => present,
        require => File['/etc/default/atftpd'],
    }

    service { 'atftpd':
        ensure    => running,
        hasstatus => false,
        require   => Package['atftpd'],
    }
}
