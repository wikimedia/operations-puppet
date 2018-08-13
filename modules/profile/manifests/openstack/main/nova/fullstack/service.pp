class profile::openstack::main::nova::fullstack::service(
    $osstackcanary_pass = hiera('profile::openstack::main::nova::fullstack_pass'),
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    $region = hiera('profile::openstack::main::region'),
    ) {

    require ::profile::openstack::main::clientlib
    class { '::profile::openstack::base::nova::fullstack::service':
        nova_api_host      => $nova_api_host,
        osstackcanary_pass => $osstackcanary_pass,
        region             => $region,
    }
    if ($::fqdn == $nova_api_host) {
        class {'::openstack::nova::fullstack::monitor':}
    }
}
