class profile::prometheus::icinga_exporter (
    Stdlib::Host               $active_host = lookup('profile::icinga::active_host'),
    Array[Stdlib::Host]        $partners    = lookup('profile::icinga::partners'),
    Array[String]              $alertmanagers = lookup('alertmanagers'),
    Optional[Hash[String[1], Struct[
      Optional[alertname] => Array[String[1]],
      Optional[instance]  => Array[String[1]]]]] $label_teams_config = lookup('profile::prometheus::icinga_exporter::label_teams_config', {default_value => undef}),
) {

  class { 'prometheus::icinga_exporter':
      export_problems    => $active_host == $::fqdn,
      alertmanagers      => $alertmanagers,
      label_teams_config => $label_teams_config,
  }
}
