class role::prometheus::mysqld_exporter {
    include passwords::prometheus

    prometheus::mysqld_exporter { 'default':
        client_password => $passwords::prometheus::db_pass,
        # TODO: collect also TokuDB metrics, but only from
        # selected nodes
        # TODO: collect table stats, but less frequently,
        # and avoid s3/dbstore/labsdb hosts
        arguments       => "-collect.global_status \
-collect.global_variables \
-collect.info_schema.processlist \
-collect.info_schema.processlist.min_time 0 \
-collect.slave_status \
-collect.perf_schema.eventsstatements \
-collect.perf_schema.eventsstatements.digest_text_limit 255 \
-collect.perf_schema.eventsstatements.limit 10 \
-collect.perf_schema.eventsstatements.timelimit 3600 \
"
    }

    $prometheus_nodes = hiera('prometheus_nodes')
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')

    ferm::service { 'prometheus-mysqld-exporter':
        proto  => 'tcp',
        port   => '9104',
        srange => "@resolve((${prometheus_ferm_nodes}))",
    }
}
