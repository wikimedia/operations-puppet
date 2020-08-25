class profile::prometheus::icinga_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Stdlib::Host        $active_host = lookup('profile::icinga::active_host'),
    Array[Stdlib::Host] $partners    = lookup('profile::icinga::partners'),
) {
  $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
  $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

  class { 'prometheus::icinga_exporter':
      export_problems => $active_host == $::fqdn,
  }

  ferm::service { 'prometheus-icinga-exporter':
    proto  => 'tcp',
    port   => '9245',
    srange => $ferm_srange,
  }
}
