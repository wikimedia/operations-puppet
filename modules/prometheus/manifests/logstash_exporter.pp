class prometheus::logstash_exporter{
  ensure_packages('prometheus-logstash-exporter')

  service { 'prometheus-logstash-exporter':
    ensure  => 'running',
    require => Package['prometheus-logstash-exporter'],
  }

  file { '/etc/default/prometheus-logstash-exporter':
    ensure  => present,
    mode    => '0644',
    notify  => Service['prometheus-logstash-exporter'],
    require => Package['prometheus-logstash-exporter'],
    content => template('prometheus/prometheus-logstash-exporter.defaults.erb'),
  }

  profile::auto_restarts::service { 'prometheus-logstash-exporter': }
}
