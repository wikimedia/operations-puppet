class prometheus::ipsec_exporter{
  ensure_packages('prometheus-ipsec-exporter')

  service { 'prometheus-ipsec-exporter':
    ensure    => 'running',
    subscribe => File['/etc/ipsec.conf'],
    require   => Package['prometheus-ipsec-exporter'],
  }
}
