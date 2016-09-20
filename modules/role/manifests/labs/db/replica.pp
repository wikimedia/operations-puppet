class role::labs::db::replica {

    system::role { 'role::labs::db::replica':
        description => 'Labs replica database',
    }

    include standard
    class { 'mariadb::packages_wmf':
        mariadb10 => true
    }
    include role::mariadb::monitor
    include base::firewall
    include role::mariadb::ferm
    include passwords::misc::scripts

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'multi',
    }

    class { 'mariadb::config':
        config        => 'mariadb/labsdb-replica.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'on',
        binlog_format => 'ROW',
    }

}
