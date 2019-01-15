class prometheus::elasticsearch_exporter::common {
    ensure_packages('prometheus-elasticsearch-exporter')
    # We will install per-cluster systemd units instead
    service { 'prometheus-elasticsearch-exporter':
        ensure  => 'stopped',
        require => Package['prometheus-elasticsearch-exporter'],
    }
    # Remove so there is no confusion about if it's referenced
    file { '/etc/default/prometheus-elasticsearch-exporter':
        ensure => absent,
    }
    # mask the default service to make sure its not restarted on package upgrades
    # Also clean up this and use the mask param for service when logstash servers have been upgraded to stretch
    exec { 'mask_default_prometheus_elasticsearch_exporter':
        command => '/bin/systemctl mask prometheus-elasticsearch-exporter.service',
        creates => '/etc/systemd/system/prometheus-elasticsearch-exporter.service',
    }
}
