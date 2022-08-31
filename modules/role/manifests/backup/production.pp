# SPDX-License-Identifier: Apache-2.0
# Storage daemon for Bacula, specific for production metadata
# (regular filesystem backups)
class role::backup::production {
    system::role { 'backup::production':
        description => 'Regular production backup storage server',
    }

    include ::profile::base::firewall
    include ::profile::base::production

    include ::profile::backup::storage::production
}
