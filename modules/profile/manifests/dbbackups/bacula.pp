# SPDX-License-Identifier: Apache-2.0
# If active, send the backups generated on /srv/backup to long term storage
# Requires including ::profile::backup::host on the role that uses it
class profile::dbbackups::bacula (
    Boolean $active = lookup('profile::dbbackups::bacula::active'),
) {
    if $active {
        # Warning: because we do-cross dc backups, this can get confusing:
        if $::site == 'eqiad' {
            # dbprovs on eqiad store data on Codfw (cross-dc)
            $jobdefaults = 'Weekly-Wed-DatabasesCodfw'
        } elsif $::site == 'codfw' {
            # dbprovs on codfw store data on eqiad (cross-dc)
            $jobdefaults = 'Weekly-Wed-DatabasesEqiad'  # to be DatabasesEqiad
        } else {
            fail('Only eqiad or codfw pools are configured for database backups.')
        }
        backup::set { 'mysql-srv-backups-dumps-latest':
            jobdefaults => $jobdefaults,
        }
        # Disable snapshoting sending to long term storage.
        # It takes a lot of space and is rarely used beyond
        # the 1 week window.
        # backup::set { 'mysql-srv-backups-snapshots-latest':
        #     jobdefaults => $jobdefaults,
        # }
    }
}
