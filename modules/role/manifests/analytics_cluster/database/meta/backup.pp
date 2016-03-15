# == Class role::analytics_cluster::database::meta::backup
# Uses mysql_wmf::mylvmbackup to take backups of the
# analytics-meta mysql instance.
#
# == Parameters
#
# [*dest*]
#   Rsync path for backup.  Default: /srv/backups/mysql/analytics-meta
#
class role::analytics_cluster::database::meta::backup(
    $dest = '/srv/backups/mysql/analytics-meta'
) {
    # Take hourly backups of the analytics-meta instance
    # and rsync those backups to $dest.
    mysql_wmf::mylvmbackup { 'analytics-meta':
        dest => $dest,
        hour => 0,
    }
}
