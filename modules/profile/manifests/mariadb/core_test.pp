class profile::mariadb::core_test (
    Stdlib::Unixpath $socket  = lookup('mariadb::socket', {'default_value' => '/run/mysqld/mysqld.sock'}),
    Stdlib::Unixpath $datadir = lookup('mariadb::datadir', {'default_value' => '/srv/sqldata'}),
    Stdlib::Unixpath $tmpdir  = lookup('mariadb::tmpdir', {'default_value' => '/srv/tmp'}),
    String $shard             = lookup('mariadb::shard'),
    String $mysql_role        = lookup('mariadb::mysql_role', {'default_value' => 'slave'}),
    String $ssl               = lookup('mariadb::ssl', {'default_value' => 'puppet-cert'}),
    String $binlog_format     = lookup('mariadb::binlog_format', {'default_value' => 'ROW'}),
    String $mw_primary        = mediawiki::state('primary_dc'),
){

    class { '::profile::mariadb::mysql_role':
        role => $mysql_role,
    }

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

    class { 'profile::mariadb::monitor::prometheus':
        socket      => $socket,
    }

    class { 'mariadb::service':
        # override not needed, default configuration changed on package
        # override => "[Service]\nLimitNOFILE=200000",
    }

    if $profile::mariadb::packages_wmf::mariadb_package in [
            'wmf-mariadb', 'wmf-mariadb10', 'wmf-mariadb101',
            'wmf-mariadb102', 'wmf-mariadb103', 'wmf-mariadb104'
    ] {
        $config_template = 'production.my.cnf.erb'
    } else {
        $config_template = 'core-mysql.my.cnf.erb'
    }
    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config           => "role/mariadb/mysqld_config/${config_template}",
        basedir          => $profile::mariadb::packages_wmf::basedir,
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
    $contact_group = 'admins'

    mariadb::monitor_readonly { [ $shard ]:
        read_only   => $read_only,
        is_critical => false,
    }

    mariadb::monitor_replication { [ $shard ]:
        multisource   => false,
        is_critical   => false,
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

    class { 'mariadb::monitor_memory': }
}
