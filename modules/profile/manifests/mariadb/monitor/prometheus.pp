class profile::mariadb::monitor::prometheus(
    $socket = '/run/mysqld/mysqld.sock',
    ) {

    class { 'role::prometheus::mysqld_exporter':
        socket => $socket,
    }
}
