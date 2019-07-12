class profile::prometheus::varnishkafka_exporter (
  Array[String] $prometheus_nodes = lookup('prometheus_nodes'),
  Hash $stats_default = lookup('profile::prometheus::varnishkafka_exporter::stats_default'),
) {
  $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
  $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

  class { 'prometheus::varnishkafka_exporter':
    stats_default => $stats_default
  }

  ferm::service { 'prometheus-varnishkafka-exporter':
    proto  => 'tcp',
    port   => '9132',
    srange => $ferm_srange,
  }
}
