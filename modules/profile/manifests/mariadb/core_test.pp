class profile::mariadb::core_test (
    String $shard             = lookup('mariadb::shard'),
    String $binlog_format     = lookup('mariadb::binlog_format', {'default_value' => 'ROW'}),
    String $wikiadmin_username = lookup('profile::mariadb::wikiadmin_username'),
    String $wikiuser_username = lookup('profile::mariadb::wikiuser_username'),
){
    require profile::mariadb::mysql_role
    require passwords::misc::scripts

    $mysql_role = $profile::mariadb::mysql_role::role

    profile::mariadb::section { $shard: }

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

    class { 'mariadb::service':
        # override not needed, default configuration changed on package
        # override => "[Service]\nLimitNOFILE=200000",
    }

    if $profile::mariadb::packages_wmf::mariadb_package in [
            'wmf-mariadb', 'wmf-mariadb10',
            'wmf-mariadb104', 'wmf-mariadb106', 'wmf-mariadb110', 'wmf-mariadb111'
    ] {
        $config_template = 'production.my.cnf.erb'
    } else {
        $config_template = 'core-mysql.my.cnf.erb'
    }
    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config           => "role/mariadb/mysqld_config/${config_template}",
        basedir          => $profile::mariadb::packages_wmf::basedir,
        p_s              => 'on',
        ssl              => 'puppet-cert',
        binlog_format    => $binlog_format,
        semi_sync        => $semi_sync,
        replication_role => $mysql_role,
    }

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

    $mw_primary = mediawiki::state('primary_dc')
    $replication_is_critical = ($mw_primary == $::site)
    $read_only = !($mw_primary == $::site and $mysql_role == 'master')  # could we have rw hosts on the secondary dc?
    $contact_group = 'admins'

    mariadb::monitor_readonly { [ $shard ]:
        read_only   => $read_only,
        is_critical => false,
    }

    mariadb::monitor_replication { [ $shard ]:
        multisource   => false,
        is_critical   => false,
        contact_group => $contact_group,
    }

    mariadb::monitor_eventscheduler { [ $shard ]:
        is_critical => false,
    }

    $heartbeat_enabled = $mysql_role == 'master'
    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $heartbeat_enabled,
    }

    class { 'mariadb::monitor_memory': }
}
