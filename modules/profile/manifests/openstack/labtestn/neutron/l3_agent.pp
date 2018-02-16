class profile::openstack::labtestn::neutron::l3_agent(
    $network_flat_interface = hiera('profile::openstack::labtestn::neutron::network_flat_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan'),
    ) {

    require ::profile::openstack::labtestn::cloudrepo
    class {'::profile::openstack::base::neutron::l3_agent':
        network_flat_interface      => $network_flat_interface,
        network_flat_interface_vlan => $network_flat_interface_vlan,
    }
    contain '::profile::openstack::base::neutron::l3_agent'
}
