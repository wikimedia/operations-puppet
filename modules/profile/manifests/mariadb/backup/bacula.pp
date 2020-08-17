# If active, send the backups generated on /srv/backup to long term storage
# Requires including ::profile::backup::host on the role that uses it
class profile::mariadb::backup::bacula (
    $active = hiera('profile::mariadb::backup::bacula::active'),
) {
    if $active {
        backup::set { 'mysql-srv-backups-dumps-latest':
            jobdefaults => 'Monthly-1st-Wed-Databases',
        }
        # Disable snapshoting sending to long term storage.
        # It takes a lot of space and is rarely used beyond
        # the 1 week window.
        # backup::set { 'mysql-srv-backups-snapshots-latest':
        #     jobdefaults => 'Weekly-Sun-Databases',
        # }
    }
}
