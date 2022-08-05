class profile::prometheus::cadvisor_exporter (
    Stdlib::Port $port = lookup('profile::prometheus::cadvisor_exporter::port'),
){
    class { 'prometheus::cadvisor_exporter':
        port   => $port,
        ensure => 'present',
    }
}
