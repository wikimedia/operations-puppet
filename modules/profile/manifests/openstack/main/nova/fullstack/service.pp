class profile::openstack::main::nova::fullstack::service(
    $osstackcanary_pass = hiera('profile::openstack::main::nova::fullstack_pass'),
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    ) {

    require ::profile::openstack::main::clientlib
    class { '::profile::openstack::base::nova::fullstack::service':
        nova_api_host      => $nova_api_host,
        osstackcanary_pass => $osstackcanary_pass,
        
    }

    class {'::openstack2::nova::fullstack::monitor':}
}
