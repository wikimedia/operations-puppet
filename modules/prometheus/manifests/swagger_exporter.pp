class prometheus::swagger_exporter(
  $ensure = 'present'
) {
  package { 'prometheus-swagger-exporter':
    ensure => $ensure
  }

  service { 'prometheus-swagger-exporter':
    ensure => ensure_service($ensure),
    enable => true,
  }

  base::service_auto_restart { 'prometheus-swagger-exporter': }
}
