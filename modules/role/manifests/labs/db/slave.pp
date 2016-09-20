class role::labs::db::slave {

    system::role { 'role::labs::db::slave':
        description => 'Labs user database slave',
    }

    include standard
    class { 'mariadb::packages_wmf':
        mariadb10 => true
    }
    include role::mariadb::monitor
    include role::mariadb::ferm
    include passwords::misc::scripts

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'tools',
    }

    class { 'mariadb::config':
        config        => 'mariadb/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'on',
        binlog_format => 'ROW',
    }

    #mariadb::monitor_replication { 'tools':
    #    multisource   => false,
    #    contact_group => 'labs',
    #}
}
