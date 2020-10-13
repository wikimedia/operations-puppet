class role::mariadb::core {
    $shard = hiera('mariadb::shard', undef)
    $mysql_role = hiera('mariadb::mysql_role', 'slave')
    $binlog_format = hiera('mariadb::binlog_format', 'ROW')
    system::role { 'mariadb::core':
        description => "Core DB Server ${shard}",
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::passwords::misc::scripts
    include ::role::mariadb::ferm
    include ::profile::mariadb::mysql_role

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

    $is_on_primary_dc = (mediawiki::state('primary_dc') == $::site)
    $is_master = ($mysql_role == 'master')
    $contact_group = 'admins'

    mariadb::monitor_replication { [ $shard ]:
        multisource   => false,
        is_critical   => $is_on_primary_dc,
        contact_group => $contact_group,
    }
    $read_only = !($is_on_primary_dc and $is_master)
    $read_only_is_critical = ($is_master and $is_on_primary_dc)
    mariadb::monitor_readonly { [ $shard ]:
        read_only     => $read_only,
        is_critical   => $read_only_is_critical,
        contact_group => $contact_group,
    }

    profile::mariadb::replication_lag { [ $shard ]: }

    class { 'mariadb::monitor_disk':
        is_critical   => $is_on_primary_dc,
        contact_group => $contact_group,
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_on_primary_dc,
        contact_group => $contact_group,
    }

    $heartbeat_enabled = $is_master
    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $heartbeat_enabled,
    }

    class { 'mariadb::monitor_memory': }
}
