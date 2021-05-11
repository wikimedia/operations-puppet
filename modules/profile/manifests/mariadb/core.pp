class profile::mariadb::core (
    Profile::Mariadb::Valid_section $shard = lookup('mariadb::shard'),
    String $binlog_format = lookup('mariadb::binlog_format', {'default_value' => 'ROW'}),
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
        config           => 'role/mariadb/mysqld_config/production.my.cnf.erb',
        basedir          => $profile::mariadb::packages_wmf::basedir,
        p_s              => 'on',
        ssl              => 'puppet-cert',
        binlog_format    => $binlog_format,
        semi_sync        => $semi_sync,
        replication_role => $mysql_role,
    }

    profile::mariadb::section { $shard: }

    class { 'profile::mariadb::grants::core': }
    class { 'profile::mariadb::grants::production':
        shard    => 'core',
        prompt   => "PRODUCTION ${shard} ${mysql_role}",
        password => $passwords::misc::scripts::mysql_root_pass,
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
        is_critical => ($is_critical and $mysql_role == 'master'),
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

    # hack; remove after wikitech moves to a standard app server
    #  T282209
    if $shard == 's6' {
        profile::mariadb::ferm_wikitech { $shard: }
    }

    class { 'mariadb::monitor_memory': }
}
