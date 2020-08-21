class profile::wmcs::db::wikireplicas::monitor (
    Array[String] $mysql_root_clients = lookup('mysql_root_clients', {default_value => []}),
) {
    # mysql monitoring and administration from root clients/tendril
    class { 'profile::mariadb::monitor::prometheus':
        socket      => '/run/mysqld/mysqld.sock',
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
