define role::prometheus::mysqld_exporter_instance (
    $socket = "/run/mysqld/mysqld.${title}.sock",
    $port = 13306,
    ) {

    prometheus::mysqld_exporter::instance { $title:
        client_socket  => $socket,
        # TODO: collect also TokuDB metrics, but only from
        # selected nodes
        # TODO: collect table stats, but less frequently,
        # and avoid s3/dbstore/labsdb hosts
        arguments      => "-collect.global_status \
-collect.global_variables \
-collect.info_schema.processlist \
-collect.info_schema.processlist.min_time 0 \
-collect.slave_status \
-collect.info_schema.tables false",
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
