# SPDX-License-Identifier: Apache-2.0
# Web dashboard for database backup monitoring
# This is currently an empty draft, parameters will be renamed on a later
# iteration.
# SPDX-License-Identifier: Apache-2.0
class profile::dbbackups::dashboard (
    $backups              = lookup('profile::dbbackups::check::backups', Hash, ),
    $freshness            = lookup('profile::dbbackups::check::freshness', Hash[String, Integer], ),
    $warn_size_percentage = lookup('profile::dbbackups::check::warn_size_percentage', Float[0.0, 100.0]),
    $crit_size_percentage = lookup('profile::dbbackups::check::crit_size_percentage', Float[0.0, 100.0]),
    $db_host              = lookup('profile::dbbackups::check::db_host', String, ),
    $db_user              = lookup('profile::dbbackups::check::db_user', String, ),
    $db_password          = lookup('profile::dbbackups::check::db_password', String, ),
    $db_database          = lookup('profile::dbbackups::check::db_database', String, ),
) {
}
