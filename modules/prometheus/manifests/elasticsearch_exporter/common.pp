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
}
