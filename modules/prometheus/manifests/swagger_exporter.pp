class prometheus::swagger_exporter(
  $ensure = 'present'
) {
  package { 'prometheus-swagger-exporter':
    ensure => $ensure
  }

  service { 'prometheus-swagger-exporter':
    ensure => stdlib::ensure($ensure, 'service'),
    enable => true,
  }

  profile::auto_restarts::service { 'prometheus-swagger-exporter': }
}
