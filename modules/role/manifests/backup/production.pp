# SPDX-License-Identifier: Apache-2.0
# Storage daemon for Bacula, specific for production metadata
# (regular filesystem backups)
class role::backup::production {
    include profile::firewall
    include profile::base::production

    include profile::backup::storage::production
}
