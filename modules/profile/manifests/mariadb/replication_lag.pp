define profile::mariadb::replication_lag(
    Integer $prom_port = 9104,
){
    monitoring::check_prometheus { "mariadb-prolonged-lag-${title}":
        ensure          => absent, # T433344
        description     => "MariaDB sustained replica lag on ${title}",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000273/mysql?orgId=1&var-server=${facts['networking']['hostname']}&var-port=${prom_port}"],
        query           => "scalar(avg_over_time(mysql_slave_status_seconds_behind_master{instance=\"${facts['networking']['hostname']}:${prom_port}\"}[5m]))",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        warning         => 5,
        critical        => 10,
        contact_group   => 'databases-testing',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/MariaDB/Troubleshooting#Incident_Response',
        migration_task  => 'T315866',
    }

}
