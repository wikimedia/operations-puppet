class profile::openstack::labtestn::neutron::l3_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $network_flat_interface = hiera('profile::openstack::labtestn::neutron::network_flat_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan'),
    $network_flat_name = hiera('profile::openstack::labtestn::neutron::network_flat_name'),
    $dmz_cidr = hiera('profile::openstack::labtestn::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::labtestn::neutron::network_public_ip'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::l3_agent':
        version                     => $version,
        network_flat_interface      => $network_flat_interface,
        network_flat_interface_vlan => $network_flat_interface_vlan,
        dmz_cidr                    => $dmz_cidr,
        network_public_ip           => $network_public_ip,
    }
    contain '::profile::openstack::base::neutron::l3_agent'

    # need to add bridge creation for bridge_mappings
    # in linuxbridge_agent.ini
    interface::tagged { 'eth1.2120':
        base_interface => 'eth1',
        vlan_id        => '2120',
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class {'::profile::openstack::base::neutron::linuxbridge_agent':
        version                => $version,
        network_flat_interface => $network_flat_interface,
        network_flat_name      => $network_flat_name,
    }
    contain '::profile::openstack::base::neutron::linuxbridge_agent'
}
