class prometheus::logstash_exporter{
  ensure_packages('prometheus-logstash-exporter')

  service { 'prometheus-logstash-exporter':
    ensure  => 'running',
    require => Package['prometheus-logstash-exporter'],
  }
}
