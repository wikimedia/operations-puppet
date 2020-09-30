class profile::mariadb::monitor::prometheus(
    $socket = '/run/mysqld/mysqld.sock',
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
){

    include passwords::prometheus

    prometheus::mysqld_exporter { 'default':
        client_password => $passwords::prometheus::db_pass,
        client_socket   => $socket,
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')

    ferm::service { 'prometheus-mysqld-exporter':
        proto  => 'tcp',
        port   => '9104',
        srange => "@resolve((${prometheus_ferm_nodes}))",
    }
}
