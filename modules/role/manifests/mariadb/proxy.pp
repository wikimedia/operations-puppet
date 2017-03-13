# generic config for a database proxy using haproxy
class role::mariadb::proxy(
    $shard
    ) {

    system::role { 'role::mariadb::proxy':
        description => "DB Proxy ${shard}",
    }

    include ::standard

    package { [
        'mysql-client',
        'percona-toolkit',
    ]:
        ensure => present,
    }

    class { 'haproxy':
        template => 'role/haproxy/db.cfg.erb',
    }
}

