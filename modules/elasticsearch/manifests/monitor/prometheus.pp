class elasticsearch::monitor::prometheus {
    ensure_packages('prometheus-elasticsearch-exporter')

    service { 'prometheus-elasticsearch-exporter':
        ensure => 'running',
    }
}
