class prometheus::elasticsearch_exporter {
  ensure_packages('prometheus-elasticsearch-exporter')

  service { 'prometheus-elasticsearch-exporter':
    ensure  => 'running',
    require => Package['prometheus-elasticsearch-exporter'],
  }
}
