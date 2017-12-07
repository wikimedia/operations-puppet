# == Class profile::analytics::database::meta::backup
#
# Uses mariadb::mylvmbackup to take backups of the analytics-meta mysql instance.
#
# == Parameters
#
# [*dest*]
#   Rsync path for backup.
#   You could include profile::analytics::database::meta::backup_dest
#   on some other node, and then set $dest here to
#   other.node.org::backup/mysql/analytics-meta/ and backups would
#   be rsynced elsewhere.
#
class profile::analytics::database::meta::backup(
    $dest = hiera('profile::analytics::database::meta::backup::rsync_dest'),
) {
    # Take hourly backups of the analytics-meta instance
    # and rsync those backups to $dest.
    mariadb::mylvmbackup { 'analytics-meta':
        dest   => $dest,
        minute => 0,
        lvname => 'mysql',
    }
}