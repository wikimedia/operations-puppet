# If active, send the backups generated on /srv/backup to long term storage
# Requires including ::profile::backup::host on the role that uses it
class profile::mariadb::backup::bacula (
    $active = hiera('profile::mariadb::backup::bacula::active'),
) {
    if $active {
        backup::set { 'mysql-srv-backups-dumps-latest': }
    }
}
