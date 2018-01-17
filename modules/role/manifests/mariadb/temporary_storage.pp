class role::mariadb::temporary_storage {
    if os_version('debian >= stretch') {
        $default_package = 'wmf-mariadb101'
    } else {
        $default_package = 'wmf-mariadb10'
    }
    $package = hiera('mariadb::package', $default_package)
    $basedir = hiera('mariadb::basedir',  "/opt/${package}")
    $socket = hiera('mariadb::socket', '/run/mysqld/mysqld.sock')
    $datadir = hiera('mariadb::datadir', '/srv/sqldata')
    $tmpdir = hiera('mariadb::tmpdir', '/srv/tmp')
    $mysql_role = hiera('mariadb::mysql_role', 'slave')
    $ssl = hiera('mariadb::ssl', 'puppet-cert')
    $binlog_format = hiera('mariadb::binlog_format', 'ROW')

    system::role { 'mariadb::core':
        description => "MariaDB temporary storage",
    }

    include ::standard
    include ::base::firewall
    include ::profile::mariadb::monitor
    include ::passwords::misc::scripts
    # mariadb port not open to the world
    # include ::role::mariadb::ferm

    # Semi-sync replication
    # off: for shard(s) of a single machine, with no slaves
    # slave: for all slaves
    # both: for masters (they are slaves and masters at the same time)
    if ($mysql_role == 'standalone') {
        $semi_sync = 'off'
    } elsif $mysql_role == 'master' {
        $semi_sync = 'master'
    } else {
        $semi_sync = 'slave'
    }

    class {'mariadb::packages_wmf':
        package => $package,
    }
    class {'mariadb::service':
        package  => $package,
        # override not needed, default configuration changed on package
        # override => "[Service]\nLimitNOFILE=200000",
    }

    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config           => 'role/mariadb/mysqld_config/production.my.cnf.erb',
        basedir          => $basedir,
        datadir          => $datadir,
        tmpdir           => $tmpdir,
        socket           => $socket,
        p_s              => 'on',
        ssl              => $ssl,
        binlog_format    => $binlog_format,
        semi_sync        => $semi_sync,
        replication_role => $mysql_role,
    }
}
