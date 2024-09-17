# SPDX-License-Identifier: Apache-2.0
# We need /srv/tftboot populated from volatile on APT repo servers,
# not just install (TFTP) servers because installer files are fetched via HTTP (T252382)
class aptrepo::tftp () {
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
        # Set max_files to avoid warning in puppetserver logs, T374885
        # We allow three debian releases, each at 300 files, as well as up to
        # ten old versions, 3 * 300 * 10
        max_files    => 9000,
        backup       => false,
    }
}
