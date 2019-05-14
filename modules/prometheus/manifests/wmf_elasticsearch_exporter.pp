# Collect metrics exposed by the search-extra elasticsearch plugin.
# See https://github.com/wikimedia/search-extra/blob/master/src/main/java/org/wikimedia/search/extra/latency/LatencyStatsAction.java
define prometheus::wmf_elasticsearch_exporter(
    Stdlib::Port $prometheus_port,
    Stdlib::Port $elasticsearch_port,
) {
    include ::prometheus::wmf_elasticsearch_exporter::common

    $service_name = "prometheus-wmf-elasticsearch-exporter-${elasticsearch_port}"
    systemd::service { $service_name:
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-wmf-elasticsearch-exporter'),
        require => File['/usr/local/bin/prometheus-wmf-elasticsearch-exporter'],
    }

    base::service_auto_restart { $service_name: }
}
