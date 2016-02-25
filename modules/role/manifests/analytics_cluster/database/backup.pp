# == Class role::analytics_cluster::database::backup
# Backs up the Analytics MySQL Meta instance with daily incremental
# backups and weekly full backups.
#
# TODO: copy backups into HDFS, delete old backups.
#
class role::analytics_cluster::database::backup {
    Class['role::analytics_cluster::database::meta'] -> Class['role::analytics_cluster::database::backup']

    # NOTE: The backup will be taken using these mysql credentials.
    #       You must manually ensure that a grant is created for them.
    include passwords::mysql::dump

    file { '/etc/mysql/conf.d/backup-credentials.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => "[client]\nuser=${passwords::mysql::dump::user}\npassword=${passwords::mysql::dump::pass}\n",
    }

    # Install mysql-innobackup script for easy regular and incremental backups.
    file { '/usr/local/bin/mysql-innobackup':
        source => 'puppet:///modules/analytics_cluster/database/mysql-innobackup',
        mode   => '0755',
    }

    logrotate::conf { 'mysql-innobackup':
        source  => 'puppet:///modules/analytics_cluster/database/mysql-innobackup.logrotate',
        require => File['/usr/local/bin/mysql-innobackup'],
    }

    file { [
        # TODO: when the analytics-meta mysql instance is moved to a new
        # host, allow puppet to manage /srv/backups.  For now /srv/backups
        # is a symlink on analytics1015.
            # '/srv/backups',
            '/srv/backups/mysql',
            '/srv/backups/mysql/analytics-meta'
        ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    # We do weekly backups, so each week the $backup_path will change.
    # This will look like:
    #   /srv/backups/mysql/analytics-meta/<year>--<week_number_in_year>
    # E.g.
    #   /srv/backups/mysql/analytics-meta/2016--35
    $backup_path = inline_template('/srv/backups/mysql/analytics-meta/<%= Time.now.strftime("%Y--%U") %>')

    # TODO: Once we are sure this works, add commands to copy backups into
    # HDFS and delete old backups.
    cron { 'mysql-innobackup-analytics-meta':
        command => "/usr/local/bin/mysql-innobackup -P 8 -p /etc/mysql/conf.d/backup-credentials.cnf ${backup_path} 2>&1 >> /var/log/mysql-innobackup.log",
        hour    => 4,
        user    => 'root',
        require => File['/usr/local/bin/mysql-innobackup'],
    }
}
