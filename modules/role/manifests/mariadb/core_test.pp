class role::mariadb::core_test {
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
    $shard = hiera('mariadb::shard', undef)
    $mysql_role = hiera('mariadb::mysql_role', 'slave')
    $ssl = hiera('mariadb::ssl', 'puppet-cert')
    $binlog_format = hiera('mariadb::binlog_format', 'ROW')
    $mw_primary = mediawiki::state('primary_dc')
    system::role { 'mariadb::core':
        description => "Core Test DB Server ${shard}",
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::mariadb::monitor
    include ::passwords::misc::scripts
    include ::role::mariadb::ferm

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

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'core',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
        socket      => $socket,
    }

    class { 'mariadb::packages_wmf':
        package => $package,
    }
    class { 'mariadb::service':
        package  => $package,
        # override not needed, default configuration changed on package
        # override => "[Service]\nLimitNOFILE=200000",
    }

    if $package in ['wmf-mariadb', 'wmf-mariadb10', 'wmf-mariadb101',
                    'wmf-mariadb102', 'wmf-mariadb103'] {
        $config_template = 'production.my.cnf.erb'
    } else {
        $config_template = 'core-mysql.my.cnf.erb'
    }
    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config           => "role/mariadb/mysqld_config/${config_template}",
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

    class { 'profile::mariadb::grants::core': }
    class { 'profile::mariadb::grants::production':
        shard    => 'core',
        prompt   => "PRODUCTION ${shard} ${mysql_role}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    $replication_is_critical = ($mw_primary == $::site)
    $read_only = !($mw_primary == $::site and $mysql_role == 'master')  # could we have rw hosts on the secondary dc?
    $contact_group = $replication_is_critical ? {
        true  => 'dba',
        false => 'admins',
    }

    mariadb::monitor_readonly { [ $shard ]:
        read_only   => $read_only,
        is_critical => false,
    }

    mariadb::monitor_replication { [ $shard ]:
        multisource   => false,
        is_critical   => $replication_is_critical,
        contact_group => $contact_group,
        socket        => $socket,
    }

    $heartbeat_enabled = $mysql_role == 'master'
    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $heartbeat_enabled,
        socket     => $socket,
    }
}
