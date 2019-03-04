define profile::prometheus::mysqld_exporter_instance (
    $socket = "/run/mysqld/mysqld.${title}.sock",
    $port = 13306,
    ) {

    prometheus::mysqld_exporter::instance { $title:
        client_socket  => $socket,
        listen_address => ":${port}",
    }

    $prometheus_nodes = hiera('prometheus_nodes')
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')

    ferm::service { "prometheus-mysqld-exporter@${title}":
        proto  => 'tcp',
        port   => $port,
        srange => "@resolve((${prometheus_ferm_nodes}))",
    }
}
