define profile::mariadb::replication_lag(
    Integer $prom_port = 9104,
){
    include ::profile::mariadb::mysql_role
    $role = $profile::mariadb::mysql_role::role
    $is_on_primary_dc = (mediawiki::state('primary_dc') == $::site)

    # Don't monitor replication lag for 'standalone' hosts, or section masters in the primary DC
    if ($role == 'master' and !$is_on_primary_dc) or $role == 'slave' {
        monitoring::check_prometheus { "mariadb-prolonged-lag-${title}":
            description     => '5-minute average replication lag is over 2s',
            dashboard_links => ["https://grafana.wikimedia.org/d/000000273/mysql?orgId=1&var-server=${::hostname}&var-port=${prom_port}&var-dc=${::site} prometheus/ops"],
            query           => "scalar(avg_over_time(mysql_slave_status_seconds_behind_master{instance=\"${::hostname}:${prom_port}\"}[5m]))",
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
            warning         => 1,
            critical        => 2,
            contact_group   => 'databases-testing',
            notes_link      => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting#Replication_lag'
        }
    }
}
