class role::prometheus::mysqld_exporter (
    $socket ='/tmp/mysql.sock',
    ) {

    include passwords::prometheus

    prometheus::mysqld_exporter { 'default':
        client_password => $passwords::prometheus::db_pass,
        client_socket   => $socket,
    }

    $prometheus_nodes = hiera('prometheus_nodes')
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')

    ferm::service { 'prometheus-mysqld-exporter':
        proto  => 'tcp',
        port   => '9104',
        srange => "@resolve((${prometheus_ferm_nodes}))",
    }
}
