# SPDX-License-Identifier: Apache-2.0
# Storage daemons for Bacula, specific to metadata and misc database backups.
class role::backup::databases {
    system::role { 'backup::databases':
        description => 'Metadata and misc database backups',
    }

    include ::profile::base::firewall
    include ::profile::base::production

    include ::profile::backup::storage::databases
}
