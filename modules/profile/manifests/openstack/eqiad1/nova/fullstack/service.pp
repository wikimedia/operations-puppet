class profile::openstack::eqiad1::nova::fullstack::service(
    $osstackcanary_pass = hiera('profile::openstack::eqiad1::nova::fullstack_pass'),
    $nova_api_host = hiera('profile::openstack::eqiad1::nova_api_host'),
    $region = hiera('profile::openstack::eqiad1::region'),
    $network = hiera('profile::openstack::eqiad1::nova::instance_network_id'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class { '::profile::openstack::base::nova::fullstack::service':
        nova_api_host      => $nova_api_host,
        osstackcanary_pass => $osstackcanary_pass,
        region             => $region,
        network            => $network,
    }
    if ($::fqdn == $nova_api_host) {
        class {'::openstack::nova::fullstack::monitor':}
    }
}
