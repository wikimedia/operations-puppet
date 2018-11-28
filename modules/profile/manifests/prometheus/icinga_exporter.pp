class profile::prometheus::icinga_exporter (
  $prometheus_nodes = hiera('prometheus_nodes'),
) {
  $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
  $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

  class { 'prometheus::icinga_exporter': }

  ferm::service { 'prometheus-icinga-exporter':
    proto  => 'tcp',
    port   => '9245',
    srange => $ferm_srange,
  }
}
