# SPDX-License-Identifier: Apache-2.0
# Main storage daemon for Bacula, specifically for default production data
# (regular filesystem backups)
class role::backup::main {
    include profile::base::production

    include profile::backup::storage::main
}
