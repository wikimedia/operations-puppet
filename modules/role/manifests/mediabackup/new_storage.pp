# SPDX-License-Identifier: Apache-2.0
#
# New backup storage for media backups
# They are the hosts that actually store the backed-up media files, but
# only talk for backup & recovery with backup workers

class role::mediabackup::new_storage {
    include profile::base::production
    include profile::firewall

    include profile::mediabackup::new_storage
}
