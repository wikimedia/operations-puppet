class prometheus::icinga_exporter(
  Wmflib::Ensure $ensure = present,
  Boolean $export_problems = false,
  Array[String] $alertmanagers = [],
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

  $icinga_am_ensure = $export_problems ? {
    true  => present,
    false => absent,
  }

  $am_urls = $alertmanagers.map |$u| { "--alertmanager.url http://${u}:9093" }

  systemd::service { 'prometheus-icinga-am':
    ensure   => $icinga_am_ensure,
    content  => init_template('prometheus-icinga-am', 'systemd_override'),
    override => true,
    restart  => true,
  }

  base::service_auto_restart { 'prometheus-icinga-am': }
}
