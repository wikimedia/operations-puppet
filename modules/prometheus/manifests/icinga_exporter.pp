class prometheus::icinga_exporter(
  $prometheus_user = 'prometheus',
  $ensure='present'
) {
  package { 'prometheus-icinga-exporter':
    ensure => $ensure,
  }

  service { 'prometheus-icinga-exporter':
    ensure => running,
    enable => true,
  }

  base::service_auto_restart { 'prometheus-icinga-exporter': }
}
