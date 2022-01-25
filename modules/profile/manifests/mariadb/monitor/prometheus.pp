class profile::mariadb::monitor::prometheus(
    $socket = '/run/mysqld/mysqld.sock',
){

    include passwords::prometheus

    prometheus::mysqld_exporter { 'default':
        client_password => $passwords::prometheus::db_pass,
        client_socket   => $socket,
    }
}
