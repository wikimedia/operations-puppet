class profile::mariadb::monitor::prometheus (
    $socket = '/run/mysqld/mysqld.sock',
) {
    include passwords::prometheus
    require profile::mariadb::mysql_role
    if $profile::mariadb::mysql_role::role == 'standalone' {
        $enable_heartbeat_monitoring = false
    } else {
        $enable_heartbeat_monitoring = true
    }
    prometheus::mysqld_exporter { 'default':
        client_password             => $passwords::prometheus::db_pass,
        client_socket               => $socket,
        enable_heartbeat_monitoring => $enable_heartbeat_monitoring,
    }
}
