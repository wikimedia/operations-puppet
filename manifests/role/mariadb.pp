
# Generic Server
class role::mariadb {

    $cluster = 'misc'

    system::role { 'role::mariadb':
        description => 'database server',
    }

    include standard
    include mariadb
}

# Beta Cluster Master
# Should add separate role for slaves
class role::mariadb::beta {

    $cluster = 'beta'

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

    $cluster = 'mysql'

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    include standard
    include mariadb::packages_wmf
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
    ) {

    $cluster = 'mysql'

    system::role { 'role::mariadb::dbstore':
        description => 'Delayed Slave',
    }

    # No packages yet! MariaDB 10 beta tarball in /opt
    #include mariadb::packages

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

    $cluster = 'mysql'

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