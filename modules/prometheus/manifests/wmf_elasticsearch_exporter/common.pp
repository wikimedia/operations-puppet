# Collect metrics exposed by the search-extra elasticsearch plugin.
# See https://github.com/wikimedia/search-extra/blob/master/src/main/java/org/wikimedia/search/extra/latency/LatencyStatsAction.java
class prometheus::wmf_elasticsearch_exporter::common {
    file { '/usr/local/bin/prometheus-wmf-elasticsearch-exporter':
        ensure => present,
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-wmf-elasticsearch-exporter.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
