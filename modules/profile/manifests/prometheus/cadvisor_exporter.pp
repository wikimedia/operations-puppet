class profile::prometheus::cadvisor_exporter (
    Stdlib::Port $port = lookup('profile::prometheus::cadvisor_exporter::port'),
){

    # We only support buster and above cause we have no incentive to support
    # stretch and below
    if debian::codename::ge('buster'){
        class { 'prometheus::cadvisor_exporter':
          port   => $port,
          ensure => 'present',
        }
    }
}
