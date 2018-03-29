class profile::openstack::base::neutron::l3_agent(
    $version = hiera('profile::openstack::base::version'),
    $dmz_cidr = hiera('profile::openstack::base::neutron::dmz_cidr'),
    $external_bridge = hiera('profile::openstack::labtestn::neutron::external_bridge'),
    $network_flat_interface_external = hiera('profile::openstack::base::neutron::network_flat_interface_external'),
    $network_public_ip = hiera('profile::openstack::base::neutron::network_public_ip'),
    ) {

    class {'::openstack::neutron::l3_agent':
        version           => $version,
        dmz_cidr          => $dmz_cidr,
        bridge            => $external_bridge,
        bridge_addif      => $network_flat_interface_external,
        network_public_ip => $network_public_ip,
    }
    contain '::openstack::neutron::l3_agent'
}
