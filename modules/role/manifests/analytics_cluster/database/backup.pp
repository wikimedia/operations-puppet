# == Class role::analytics_cluster::database::backup
# Backs up the Analytics MySQL Meta instance daily.
# Uses xtrabackup, innodb only, and bpipe.
class role::analytics_cluster::database::backup {
    Class['role::analytics_cluster::database::meta'] -> Class['role::analytics_cluster::database::backup']

    include role::backup::host

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

    file { ['/srv/backups', '/srv/backups/mysql']:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    backup::mysqlset {'analytics-meta':
        xtrabackup       => true,
        per_db           => true,
        innodb_only      => true,
        binlog           => false,
        slave            => false,
        local_dump_dir   => '/srv/backups/mysql',
        password_file    => '/etc/mysql/conf.d/backup-credentials.cnf',
        method           => 'bpipe',
        mysql_binary     => '/usr/local/bin/mysql',
        mysqldump_binary => '/usr/local/bin/mysqldump',
        jobdefaults      => 'daily',
    }
}
