# If active, send the backups generated on /srv/backup to long term storage
# Requires including ::profile::backup::host on the role that uses it
class profile::mariadb::backup::bacula (
    Boolean $active = lookup('profile::mariadb::backup::bacula::active'),
) {
    if $active {
        # Warning: because we do-cross dc backups, this can get confusing:
        if $::site == 'eqiad' {
            # dbprovs on eqiad store data on Codfw (cross-dc)
            $pool = 'DatabasesCodfw'
        } elsif $::site == 'codfw' {
            # dbprovs on codfw store data on eqiad (cross-dc)
            $pool = 'Databases'
        } else {
            fail('Only eqiad or codfw pools are configured for database backups.')
        }
        $dump_schedule = 'Monthly-1st-Wed'
        backup::set { 'mysql-srv-backups-dumps-latest':
            jobdefaults => "${dump_schedule}-${pool}",
        }
        # Disable snapshoting sending to long term storage.
        # It takes a lot of space and is rarely used beyond
        # the 1 week window.
        # $snapshot_schedule = 'Weekly-Sun'
        # backup::set { 'mysql-srv-backups-snapshots-latest':
        #     jobdefaults => "${snapshot_schedule}-${pool}",
        # }
    }
}
