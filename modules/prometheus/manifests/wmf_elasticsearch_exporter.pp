# Collect metrics exposed by the search-extra elasticsearch plugin.
# See https://github.com/wikimedia/search-extra/blob/master/src/main/java/org/wikimedia/search/extra/latency/LatencyStatsAction.java
class prometheus::wmf_elasticsearch_exporter {
    file { '/usr/local/bin/prometheus-wmf-elasticsearch-exporter':
        ensure => present,
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-wmf-elasticsearch-exporter',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::service { 'prometheus-wmf-elasticsearch-exporter':
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-wmf-elasticsearch-exporter'),
        require => File['/usr/local/bin/prometheus-wmf-elasticsearch-exporter'],
    }
}
