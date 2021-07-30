class profile::prometheus::icinga_exporter (
    Array[Stdlib::Host]        $prometheus_nodes = lookup('prometheus_nodes'),
    Stdlib::Host               $active_host = lookup('profile::icinga::active_host'),
    Array[Stdlib::Host]        $partners    = lookup('profile::icinga::partners'),
    Array[String]              $alertmanagers = lookup('alertmanagers'),
    Optional[Hash[String[1], Struct[
      Optional[alertname] => Array[String[1]],
      Optional[instance]  => Array[String[1]]]]] $label_teams_config = lookup('profile::prometheus::icinga_exporter::label_teams_config', {default_value => undef}),
) {
  $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
  $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

  class { 'prometheus::icinga_exporter':
      export_problems    => $active_host == $::fqdn,
      alertmanagers      => $alertmanagers,
      label_teams_config => $label_teams_config,
  }

  ferm::service { 'prometheus-icinga-exporter':
    proto  => 'tcp',
    port   => '9245',
    srange => $ferm_srange,
  }

  ferm::service { 'prometheus-icinga-am':
    proto  => 'tcp',
    port   => '9247',
    srange => $ferm_srange,
  }
}
