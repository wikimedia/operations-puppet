class prometheus::elasticsearch_exporter::common {
    ensure_packages('prometheus-elasticsearch-exporter')
    # We will install per-cluster systemd units instead
    # mask the default service to make sure its not restarted on package upgrades
    service { 'prometheus-elasticsearch-exporter':
        ensure  => 'stopped',
        require => Package['prometheus-elasticsearch-exporter'],
        enable  => 'mask',
    }
    # Remove so there is no confusion about if it's referenced
    file { '/etc/default/prometheus-elasticsearch-exporter':
        ensure => absent,
    }
}
