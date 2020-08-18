class prometheus::icinga_exporter(
  $prometheus_user = 'prometheus',
  $ensure='present'
) {
  package { 'prometheus-icinga-exporter':
    ensure => $ensure,
  }

  systemd::service { 'prometheus-icinga-exporter':
    ensure   => present,
    content  => init_template('prometheus-icinga-exporter', 'systemd_override'),
    override => true,
    restart  => true,
  }

  base::service_auto_restart { 'prometheus-icinga-exporter': }
}
