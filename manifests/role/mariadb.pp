# Generic Server
class role::mariadb {

    system::role { 'role::mariadb':
        description => 'database server',
    }

    include standard
    include mariadb
}

# miscellaneous services clusters
class role::mariadb::misc(
    $shard
    ) {

    system::role { 'role::mariadb::misc':
        description => "Misc Services Database ${shard}",
    }

    include standard
    include mariadb::packages_wmf
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => "MISC ${shard}",
        config   => 'mariadb/misc.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        contact_group => 'admins',
    }
}

# Phab pretty much requires its own sandbox
# strict sql_mode -- nice! but other services moan
# admin tool that needs non-trivial permissions
class role::mariadb::misc::phabricator(
    $shard    = 'm3',
    $master   = false,
    $snapshot = false,
    ) {

    system::role { 'role::mariadb::misc':
        description => "Misc Services Database ${shard} (phabricator)",
    }

    include standard
    include mariadb::packages_wmf
    include passwords::misc::scripts

    $read_only = $master ? {
        true  => 'off',
        false => 'on',
    }

    class { 'mariadb::config':
        prompt    => "MISC ${shard}",
        config    => 'mariadb/misc.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/a/sqldata',
        tmpdir    => '/a/tmp',
        sql_mode  => 'STRICT_ALL_TABLES',
        read_only => $read_only,
    }

    if $snapshot {
        include coredb_mysql::snapshot
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        contact_group => 'admins',
    }

    unless $master {
        mariadb::monitor_replication { [ $shard ]:
            multisource => false,
        }
    }
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

# MariaDB 10 slaves replicating all shards
class role::mariadb::dbstore(
    $lag_warn = 300,
    $lag_crit = 600,
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

class role::mariadb::backup::config {
    if $mariadb_backups_folder {
        $folder = $mariadb_backups_folder
    } else {
        $folder = '/srv/backups'
    }
}

class role::mariadb::backup {
    include backup::host
    include passwords::mysql::dump

    include role::mariadb::backup::config
    $backups_folder = $role::mariadb::backup::config::folder

    file { $backups_folder:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0600', # implicitly 0700 for dirs
    }

    file { '/etc/mysql/conf.d/dumps.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => "[client]\nuser=${passwords::mysql::dump::user}\npassword=${passwords::mysql::dump::pass}\n",
    }

    backup::mysqlset {'dbstore':
        xtrabackup       => false,
        per_db           => true,
        innodb_only      => true,
        local_dump_dir   => $backups_folder,
        password_file    => '/etc/mysql/conf.d/dumps.cnf',
        method           => 'predump',
        mysql_binary     => '/usr/local/bin/mysql',
        mysqldump_binary => '/usr/local/bin/mysqldump',
        jobdefaults      => "Weekly-${backup::host::day}-${backup::host::pool}",
    }
}

class role::mariadb::core(
    $shard
    ) {

    system::role { "role::mariadb::core":
        description => "Core DB Server ${shard}",
    }

    include standard
    include passwords::misc::scripts

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        prompt    => "PRODUCTION ${shard}",
        config    => 'mariadb/production.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
    }

    include mariadb::monitor_disk
    #include mariadb::monitor_process
}
