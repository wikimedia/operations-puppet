# Class: install_server::tftp_server
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
#   include install_server::tftp_server

class install_server::tftp_server () {

    file { '/srv/tftpboot':
        # config files in the puppet repository,
        # larger files like binary images in volatile
        source       => [
            'puppet:///modules/install_server/tftpboot',
            # lint:ignore:puppet_url_without_modules
            'puppet:///volatile/tftpboot',
            # lint:endignore
        ],
        sourceselect => all,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        recurse      => true,
        purge        => true,
        force        => true,
        # Set max_files to avoid warning in puppetserver logs
        # We allow three debian releases, each at 300 files, as well as up to
        # ten old versions, 3 * 300 * 10
        max_files    => 9000,
        backup       => false,
    }

    file { '/etc/default/atftpd':
        mode   => '0444',
        source => 'puppet:///modules/install_server/atftpd-default',
    }

    ensure_packages('atftpd')
}
