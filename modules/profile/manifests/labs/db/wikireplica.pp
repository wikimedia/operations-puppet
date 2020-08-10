class profile::labs::db::wikireplica (
    Array[String] $mysql_root_clients = hiera('mysql_root_clients', []),
) {
    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients_str = join($mysql_root_clients, ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients_str})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients_str})",
    }

    ferm::service { 'mysql_labs_db_proxy':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '(@resolve((dbproxy1018.eqiad.wmnet)) @resolve((dbproxy1019.eqiad.wmnet)))',
    }

    ferm::service { 'mysql_labs_db_admin':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '(@resolve((labstore1004.eqiad.wmnet)) @resolve((labstore1005.eqiad.wmnet)))',
    }

    class { 'profile::mariadb::monitor::prometheus':
        socket      => '/run/mysqld/mysqld.sock',
    }
    if os_version('debian == buster') {
        $basedir = '/opt/wmf-mariadb104/'
    }
    else {
        $basedir = '/opt/wmf-mariadb101/'
    }
    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/labsdb-replica.my.cnf.erb',
        basedir       => $basedir,
        datadir       => '/srv/sqldata',
        socket        => '/run/mysqld/mysqld.sock',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

    mariadb::monitor_readonly{ 'wikireplica':
        port      => 3306,
        read_only => 1,
    }

    class { 'mariadb::monitor_memory':
        warning  => 92,
        critical => 97,
    }
}
