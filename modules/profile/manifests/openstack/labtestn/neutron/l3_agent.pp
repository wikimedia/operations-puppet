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

    interface::tagged { 'eth1.2120':
        base_interface => 'eth1',
        vlan_id        => '2120',
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }
}
