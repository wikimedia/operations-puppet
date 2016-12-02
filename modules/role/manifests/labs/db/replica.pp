class role::labs::db::replica {

    system::role { 'role::labs::db::replica':
        description => 'Labs replica database',
    }

    include standard
    class { 'mariadb::packages_wmf':
        package => 'wmf-mariadb101',
    }
    class { 'mariadb::service':
        package => 'wmf-mariadb101',
    }
    include role::mariadb::monitor
    include base::firewall
    include role::mariadb::ferm
    include passwords::misc::scripts

    # add when labsdb1009/10/11 are in service
    # include role::labs::db::common
    # include role::labs::db::views
    # include role::labs::db::check_private_data

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'multi',
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/labsdb-replica.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

}
