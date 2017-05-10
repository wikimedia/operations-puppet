class role::mariadb::core(
    $shard,
    $ssl           = 'puppet-cert',
    $binlog_format = 'MIXED',
    $master        = false,
    ) {

    system::role { 'role::mariadb::core':
        description => "Core DB Server ${shard}",
    }

    include ::standard
    include ::base::firewall
    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm

    # Semi-sync replication
    # off: for shard(s) of a single machine, with no slaves
    # slave: for all slaves
    # both: for masters (they are slaves and masters at the same time)
    if ($shard == 'es1') {
        $mysql_role = 'standalone'
        $semi_sync = 'off'
    } elsif $master == true {
        $mysql_role = 'master'
        $semi_sync = 'both'
    } else {
        $mysql_role = 'slave'
        $semi_sync = 'slave'
    }

    class { 'role::mariadb::groups':
        mysql_group => 'core',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    # FIXME: Get package, socket, datadir, etc. from hiera
    # FIXME: Support multiple instances per host
    # db2062 is a one-time test of MariaDB 10.1, which doesn't have yet
    # proper support (see T148507 & T116557)
    if ($::hostname == 'db2062') {
        class {'mariadb::packages_wmf':
            package => 'wmf-mariadb101',
        }
        class {'mariadb::service':
            package => 'wmf-mariadb101',
        }
    } else {
        include mariadb::packages_wmf
        include mariadb::service
    }

    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config           => 'role/mariadb/mysqld_config/production.my.cnf.erb',
        datadir          => '/srv/sqldata',
        tmpdir           => '/srv/tmp',
        p_s              => 'on',
        ssl              => $ssl,
        binlog_format    => $binlog_format,
        semi_sync        => $semi_sync,
        replication_role => $mysql_role,
    }

    include role::mariadb::grants::core
    class { 'role::mariadb::grants::production':
        shard    => 'core',
        prompt   => "PRODUCTION ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    $replication_is_critical = ($::mw_primary == $::site)
    $contact_group = $replication_is_critical ? {
        true  => 'dba',
        false => 'admins',
    }

    mariadb::monitor_replication { [ $shard ]:
        multisource   => false,
        is_critical   => $replication_is_critical,
        contact_group => $contact_group,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }
}
