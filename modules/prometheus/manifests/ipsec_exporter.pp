class prometheus::ipsec_exporter{
  ensure_packages('prometheus-ipsec-exporter')

  service { 'prometheus-ipsec-exporter':
    ensure  => 'running',
    require => Package['prometheus-ipsec-exporter'],
  }
}
