class profile::prometheus::cadvisor_exporter (
    Stdlib::Port        $port             = lookup('profile::prometheus::cadvisor_exporter::port'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
){

    class { 'prometheus::cadvisor_exporter':
      port   => $port,
      ensure => 'present',
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    ferm::service { 'prometheus-cadvisor-exporter':
      proto  => 'tcp',
      port   => $port,
      srange => $ferm_srange,
    }
}
