class role::mariadb::backup {
    include profile::backup::host
    include passwords::mysql::dump

    file { '/srv/backups':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0600', # implicitly 0700 for dirs
    }

    file { '/usr/local/bin/dumps-misc.sh':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('role/mariadb/backups/dumps-misc.sh.erb'),
    }

    file { '/etc/mysql/conf.d/dumps.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => "[client]\nuser=${passwords::mysql::dump::user}\npassword=${passwords::mysql::dump::pass}\n",
    }

    cron { 'dumps-misc':
        minute  => 0,
        hour    => 1,
        weekday => 3,
        user    => 'root',
        command => '/usr/local/bin/dumps-misc.sh >/srv/dumps-misc.log 2>&1',
        require => [File['/usr/local/bin/dumps-misc.sh'],
                    File['/srv/backups'],
        ],
    }

    backup::mysqlset {'dbstore':
        xtrabackup       => false,
        per_db           => true,
        innodb_only      => true,
        binlog           => false,
        slave            => true,
        local_dump_dir   => '/srv/backups',
        password_file    => '/etc/mysql/conf.d/dumps.cnf',
        method           => 'predump',
        mysql_binary     => '/usr/local/bin/mysql',
        mysqldump_binary => '/usr/local/bin/mysqldump',
        jobdefaults      => "Weekly-${profile::backup::host::day}-${role::backup::host::pool}",
    }
}
