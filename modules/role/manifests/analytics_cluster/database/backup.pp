# == Class role::analytics_cluster::database::backup
# Backs up the Analytics MySQL Meta instance with daily incremental
# backups and weekly full backups.
#
# TODO: copy backups into HDFS, delete old backups.
#
class role::analytics_cluster::database::backup {
    Class['role::analytics_cluster::database::meta'] -> Class['role::analytics_cluster::database::backup']

    file { [
        # TODO: when the analytics-meta mysql instance is moved to a new
        # host, allow puppet to manage /srv/backups.  For now /srv/backups
        # is a symlink on analytics1015.
            # '/srv/backups',
            '/srv/backups/mysql',
            '/srv/backups/mysql/analytics-meta'
        ]:
        ensure => 'directory',
        mode   => '0755',
    }

    # We do weekly backups, so each week the $backup_path will change.
    # This will look like:
    #   /srv/backups/mysql/analytics-meta/<year>--<week_number_in_year>
    # E.g.
    #   /srv/backups/mysql/analytics-meta/2016--35
    $backup_path = inline_template('/srv/backups/mysql/analytics-meta/<%= Time.now.strftime("%Y--%U") %>')

    # TODO: Once we are sure this works, add puppetization to copy backups into
    # HDFS and delete old backups.
    mysql_wmf::backupex::job { 'analytics-meta':
        basedir  => $backup_path,
        hour     => 4,
        parallel => 8,
    }
}
