class prometheus::icinga_exporter(
  Wmflib::Ensure $ensure = present,
  Boolean $export_problems = false,
  Array[String] $alertmanagers = [],
  Optional[Hash[
    String[1],
    Struct[
      Optional[alertname] => Array[String[1]],
      Optional[instance]  => Array[String[1]]]]] $label_teams_config = undef,
) {
  package { 'prometheus-icinga-exporter':
    ensure => $ensure,
  }

  $label_teams_config_file = '/etc/prometheus/icinga_exporter.label_teams.yml'
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
  $label_teams_config_file_ensure = $icinga_am_ensure ? {
    present => $label_teams_config ? {
      undef   => absent,
      default =>  present,
    },
    absent  =>  absent,
  }

  systemd::service { 'prometheus-icinga-am':
    ensure   => $icinga_am_ensure,
    content  => init_template('prometheus-icinga-am', 'systemd_override'),
    override => true,
    restart  => true,
  }

  base::service_auto_restart { 'prometheus-icinga-am': }

  $label_teams_yaml_config = $label_teams_config ? {
    undef   => '',
    default => $label_teams_config.to_yaml,
  }
  file{ $label_teams_config_file:
    ensure  => $label_teams_config_file_ensure,
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => $label_teams_yaml_config,
    notify  => Service['prometheus-icinga-am']
  }
}
