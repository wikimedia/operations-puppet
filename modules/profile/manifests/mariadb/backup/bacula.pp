# If active, send the backups generated on /srv/backup to long term storage
class profile::mariadb::backup::bacula (
    $active = hiera('profile::mariadb::backups::mydumper::active', false),
) {
    if $active {
        backup::set { 'mysql-srv-backups': }
    }
}
