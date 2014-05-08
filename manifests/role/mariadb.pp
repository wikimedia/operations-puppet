# Generic Server
class role::mariadb {

    system::role { 'role::mariadb':
        description => 'database server',
    }

    include standard
    include mariadb
}

# miscellaneous services clusters m[123], but currently only m3
class role::mariadb::misc {

    system::role { 'role::mariadb::misc':
        description => 'miscellaneous services database',
    }

    include standard
    include mariadb::packages_wmf
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'MISC',
        config   => 'mariadb/misc.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }

    include mariadb::monitor_disk
    include mariadb::monitor_process
}

# Beta Cluster Master
# Should add separate role for slaves
class role::mariadb::beta {

    system::role { 'role::mariadb::beta':
        description => 'beta cluster database server',
    }

    include standard
    include mariadb::packages
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'BETA',
        config   => 'mariadb/beta.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_beta_root_pass,
        datadir  => '/mnt/sqldata',
        tmpdir   => '/mnt/tmp',
    }
}

# What db1044 presently does...
class role::mariadb::tendril {

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include standard
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'TENDRIL',
        config   => 'mariadb/tendril.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }

    include mariadb::monitor_disk
    include mariadb::monitor_process
}

# MariaDB 10 delayed slaves replicating all shards
class role::mariadb::dbstore(
    $lag_warn = 90000,
    $lag_crit = 180000,
    $backups_folder = '/srv/backups',
    ) {

    system::role { 'role::mariadb::dbstore':
        description => 'Delayed Slave',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include standard
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'DBSTORE',
        config   => 'mariadb/dbstore.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }

    include mariadb::monitor_disk
    include mariadb::monitor_process

    mariadb::monitor_replication { ['s1','s2','s3','s4','s5','s6','s7','m2']:
        lag_warn => $lag_warn,
        lag_crit => $lag_crit,
    }

    include backup::host
    include passwords::mysql::dump


    file { $backups_folder:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0600', # 0700 for dirs
    }

    file { '/etc/mysql/conf.d/dumps.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => "[client]\nuser=${passwords::mysql::dump::user}\npassword=${passwords::mysql::dump::pass}\n",
    }

    backup::mysqlset {'dbstore':
        xtrabackup     => false,
        per_db         => true,
        innodb_only    => true,
        local_dump_dir => $backups_folder,
        password_file  => '/etc/mysql/conf.d/dumps.cnf',
        method         => 'predump',
    }
}

# MariaDB 10 Analytics all-shards slave, with scratch space and TokuDB
class role::mariadb::analytics {

    system::role { 'role::mariadb::analytics':
        description => 'Analytics All-Shards Slave',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include standard
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'ANALYTICS',
        config   => 'mariadb/analytics.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }

    include mariadb::monitor_disk
    include mariadb::monitor_process

    mariadb::monitor_replication { ['s1', 'm2' ]: }
}
