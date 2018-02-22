class role::labs::db::replica {

    system::role { 'labs::db::replica':
        description => 'Labs replica database',
    }

    include ::standard
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::profile::mariadb::monitor
    include ::profile::base::firewall


    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients = join($::network::constants::special_hosts['production']['mysql_root_clients'], ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients})",
    }

    ferm::service { 'mysql_labs_db_proxy':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '(@resolve((dbproxy1010.eqiad.wmnet)) @resolve((dbproxy1011.eqiad.wmnet)))',
    }

    ferm::service { 'mysql_labs_db_admin':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '(@resolve((labstore1004.eqiad.wmnet)) @resolve((labstore1005.eqiad.wmnet)))',
    }

    include ::passwords::misc::scripts

    include ::role::labs::db::common
    include ::role::labs::db::views
    include ::role::labs::db::check_private_data

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'multi',
        socket      => '/run/mysqld/mysqld.sock',
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/labsdb-replica.my.cnf.erb',
        basedir       => '/opt/wmf-mariadb101',
        datadir       => '/srv/sqldata',
        socket        => '/run/mysqld/mysqld.sock',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

}
