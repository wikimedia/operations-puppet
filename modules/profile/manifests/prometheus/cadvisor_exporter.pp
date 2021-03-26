class profile::prometheus::cadvisor_exporter (
    Stdlib::Port        $port             = lookup('profile::prometheus::cadvisor_exporter::port'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
){

    # We only support buster and above cause we have no incentive to support
    # stretch and below
    if debian::codename::ge('buster'){
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
}
