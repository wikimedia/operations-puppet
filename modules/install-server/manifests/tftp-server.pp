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
    file {
        '/srv/tftpboot':
            # config files in the puppet repository,
            # larger files like binary images in volatile
            source          => [ 'puppet:///modules/install-server/tftpboot', 'puppet:///volatile/tftpboot' ],
            sourceselect    => all,
            mode            => '0444',
            owner           => 'root',
            group           => 'root',
            recurse         => remote;
        '/srv/tftpboot/restricted/':
            ensure  => directory,
            mode    => '0755',
            owner   => 'root',
            group   => 'root';
        '/tftpboot':
            ensure => link,
            target => '/srv/tftpboot';
    }

    # TODO: Remove this it package has been purged everywhere
    package { 'openbsd-inetd':
        ensure => purged,
    }

    file { '/etc/default/atftpd':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/install-server/atftpd-default',
    }

    # Started by inetd
    package { 'atftpd':
        ensure  => latest,
        require => File['/etc/default/atftpd'],
    }
}
