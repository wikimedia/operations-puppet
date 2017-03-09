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

    if ($shard == 'es1') {
        $mysql_role = 'standalone'
    } elsif $master == true {
        $mysql_role = 'master'
    } else {
        $mysql_role = 'slave'
    }

    class { 'role::mariadb::groups':
        mysql_group => 'core',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }


    include mariadb::packages_wmf
    include mariadb::service

    # Semi-sync replication
    # off: for non-primary datacenter and read-only shard(s)
    # slave: for slaves in the primary datacenter
    # master: for masters in the primary datacenter
    if ($::mw_primary != $::site or $shard == 'es1') {
        $semi_sync = 'off'
    } elsif ($master) {
        $semi_sync = 'master'
    } else {
        $semi_sync = 'slave'
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
