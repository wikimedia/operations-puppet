class profile::openstack::labtestn::neutron::l3_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $network_flat_interface = hiera('profile::openstack::labtestn::neutron::network_flat_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::l3_agent':
        version                     => $version,
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

    $ext_ip = $facts['hostname'] ? {
        'labtestneutron2001' => '10.192.22.4',
        'labtestneutron2002' => '10.192.22.5',
    }

    interface::ip { 'eth1.2120':
        interface => 'eth1.2120',
        address   => $ext_ip,
        prefixlen => '24',
        require   => Interface::Tagged['eth1.2120'],
    }
}
