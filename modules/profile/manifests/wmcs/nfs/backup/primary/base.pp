# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::nfs::backup::primary::base {
    class {'labstore::backup_keys': }

    file {'/srv/backup':
        ensure  => 'directory',
    }

    include ::profile::base::firewall
}
