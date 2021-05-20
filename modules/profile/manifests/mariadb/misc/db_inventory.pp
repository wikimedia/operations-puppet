class profile::mariadb::misc::db_inventory(
    Optional[String[1]] $innodb_pool_size = lookup('profile::mariadb::misc::db_inventory::innodb_pool_size', {'default_value' => undef}),
) {
    include passwords::misc::scripts

    include profile::mariadb::mysql_role
    include profile::mariadb::misc::tendril
    include profile::mariadb::misc::zarcillo

    $id = 'db_inventory'
    # As the included profiles use both 'tendril' and 'zarcillo' as section names,
    # and 'db_inventory' isn't a valid section name, for the purposes of
    # profile::mariadb::section_params use 'tendril' as the name.
    $shard = 'tendril'
    $mysql_role = $profile::mariadb::mysql_role::role
    $binlog_format = $mysql_role == 'master' ? {
        true    => 'STATEMENT',
        default => 'ROW',
    }
    $is_writeable_dc = profile::mariadb::section_params::is_writeable_dc($shard)

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    profile::mariadb::ferm { $id: }

    class { 'mariadb::config':
        basedir          => $profile::mariadb::packages_wmf::basedir,
        config           => 'profile/mariadb/mysqld_config/db_inventory.my.cnf.erb',
        datadir          => '/srv/sqldata',
        tmpdir           => '/srv/tmp',
        binlog_format    => $binlog_format,
        p_s              => 'on',
        ssl              => 'puppet-cert',
        innodb_pool_size => $innodb_pool_size,
    }

    include profile::mariadb::monitor::prometheus

    if profile::mariadb::section_params::is_repl_client($shard, $mysql_role) {
        $source_dc = profile::mariadb::section_params::get_repl_src_dc($mysql_role)
        mariadb::monitor_replication { $id:
            # Ignore $is_writeable_dc for now, as both hosts are writeable.
            # See T266003 for context.
            #is_critical => $is_writeable_dc,
            is_critical => true,
            source_dc   => $source_dc
        }
        profile::mariadb::replication_lag { $id: }
    }


    $is_read_only = profile::mariadb::section_params::is_read_only($shard, $mysql_role)
    $is_critical = profile::mariadb::section_params::is_alert_critical($shard, $mysql_role)
    mariadb::monitor_readonly { $id:
        # Ignore $is_writeable_dc for now, as both hosts are writeable.
        # See T266003 for context.
        #read_only   => $is_read_only,
        read_only   => false,
        is_critical => $is_critical,
    }
    class { 'mariadb::monitor_disk':
        is_critical => $is_critical,
    }
    class { 'mariadb::monitor_process':
        is_critical => $is_critical,
    }

    class { 'mariadb::heartbeat':
        shard                  => $id,
        datacenter             => $::site,
        enabled                => $mysql_role == 'master',
        # As tendril requires READ-COMMITTED, heartbeat needs to use ROW.
        # https://phabricator.wikimedia.org/T283228#7100571
        override_binlog_format => 'ROW',
    }

    class { 'mariadb::monitor_memory': }
}
