class profile::mariadb::core (
    Profile::Mariadb::Valid_section $shard = lookup('mariadb::shard'),
    String $binlog_format = lookup('mariadb::binlog_format', {'default_value' => 'ROW'}),
    String $sync_binlog = lookup('profile::mariadb::config::sync_binlog', {'default_value' => '1'}),
    String $flush_log_at_trx_commit = lookup('profile::mariadb::config::innodb_flush_log_at_trx_commit', {'default_value' => '1'}),
    String $wikiadmin_username = lookup('profile::mariadb::wikiadmin_username'),
    String $wikiuser_username = lookup('profile::mariadb::wikiuser_username'),
){
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

    $is_writeable_dc = profile::mariadb::section_params::is_writeable_dc($shard)

    if profile::mariadb::section_params::is_repl_client($shard, $mysql_role) {
        $source_dc = profile::mariadb::section_params::get_repl_src_dc($mysql_role)
        mariadb::monitor_replication { $shard:
            is_critical => $is_writeable_dc,
            source_dc   => $source_dc,
        }
        profile::mariadb::replication_lag { $shard: }
    }

    $is_read_only = profile::mariadb::section_params::is_read_only($shard, $mysql_role)
    $is_critical = profile::mariadb::section_params::is_alert_critical($shard, $mysql_role)
    mariadb::monitor_readonly { $shard:
        read_only   => $is_read_only,
        # XXX(kormat): Not using $is_critical, as we want to alert even for an inactive DC.
        is_critical => ($mysql_role == 'master'),
    }

    class { 'mariadb::monitor_disk':
        is_critical   => $is_critical,
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_critical,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $mysql_role == 'master',
    }

    class { 'mariadb::monitor_memory': }
}
