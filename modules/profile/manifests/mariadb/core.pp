class profile::mariadb::core (
    Profile::Mariadb::Valid_section $shard = lookup('mariadb::shard'),
    String $binlog_format = lookup('mariadb::binlog_format', {'default_value' => 'ROW'}),
    String $sync_binlog = lookup('profile::mariadb::config::sync_binlog', {'default_value' => '1'}),
    String $flush_log_at_trx_commit = lookup('profile::mariadb::config::innodb_flush_log_at_trx_commit', {'default_value' => '1'}),
    Integer $expire_logs_days = lookup('profile::mariadb::config::expire_logs_days', {'default_value' => 30}),
    String $wikiadmin_username = lookup('profile::mariadb::wikiadmin_username'),
    String $wikiuser_username = lookup('profile::mariadb::wikiuser_username'),
){
    profile::mariadb::firewall { 'core': }
    require profile::mariadb::mysql_role
    require passwords::misc::scripts

    $mysql_role = $profile::mariadb::mysql_role::role

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

    include profile::mariadb::monitor::prometheus

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class {'mariadb::service':
        # override not needed, default configuration changed on package
        # override => "[Service]\nLimitNOFILE=200000",
    }

    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config                  => 'role/mariadb/mysqld_config/production.my.cnf.erb',
        basedir                 => $profile::mariadb::packages_wmf::basedir,
        p_s                     => 'on',
        ssl                     => 'puppet-cert',
        binlog_format           => $binlog_format,
        semi_sync               => $semi_sync,
        replication_role        => $mysql_role,
        sync_binlog             => $sync_binlog,
        flush_log_at_trx_commit => $flush_log_at_trx_commit,
        expire_logs_days        => $expire_logs_days,
    }

    profile::mariadb::section { $shard: }

    profile::mariadb::grants::core { $shard:
        wikiadmin_username => $wikiadmin_username,
        wikiadmin_pass     => $passwords::misc::scripts::wikiadmin_pass,
        wikiuser_username  => $wikiuser_username,
        wikiuser_pass      => $passwords::misc::scripts::wikiuser_pass,
    }
    class { 'profile::mariadb::grants::production':
        shard    => 'core',
        prompt   => "PRODUCTION ${shard} ${mysql_role}",
        password => $passwords::misc::scripts::mysql_cumin_pass,
    }

    # We want to alert on replication lag for shards that are replication clients
    if profile::mariadb::section_params::is_repl_client($shard, $mysql_role) {
        $source_dc = profile::mariadb::section_params::get_repl_src_dc($mysql_role)
        mariadb::monitor_replication { $shard:
            is_critical => true,
            source_dc   => $source_dc,
        }
    }

    $is_read_only = profile::mariadb::section_params::is_read_only($shard, $mysql_role)
    $is_critical = profile::mariadb::section_params::is_alert_critical($shard, $mysql_role)
    mariadb::monitor_readonly { $shard:
        read_only   => $is_read_only,
        # XXX(kormat): Not using $is_critical, as we want to alert even for an inactive DC.
        is_critical => ($mysql_role == 'master'),
    }

    class { 'mariadb::monitor_disk':
        is_critical => $is_critical,
    }

    mariadb::monitor_eventscheduler { $shard:
            is_critical => false,
        }

    mariadb::monitor_events { [ $shard ]:
        is_critical => false,
    }

    class { 'mariadb::monitor_process':
        is_critical => $is_critical,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $mysql_role == 'master',
    }

    if $mysql_role == 'master' {
        class { 'mariadb::monitor_heartbeat': }
    }

    class { 'mariadb::monitor_memory': }
}
