class profile::openstack::labtestn::neutron::l3_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $bridges = hiera('profile::openstack::labtestn::neutron::l3_agent_bridges'),
    $bridge_mappings = hiera('profile::openstack::labtestn::neutron::l3_agent_bridge_mappings'),
    $network_flat_interface_external = hiera('profile::openstack::labtestn::neutron::network_flat_interface_external'),
    $network_flat_interface_vlan_external = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface = hiera('profile::openstack::labtestn::neutron::network_flat_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan'),
    $dmz_cidr = hiera('profile::openstack::labtestn::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::labtestn::neutron::network_public_ip'),
    $report_interval = hiera('profile::openstack::labtestn::neutron::report_interval'),
    ) {

    interface::tagged { $network_flat_interface_external:
        base_interface => 'eth1',
        vlan_id        => $network_flat_interface_vlan_external,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    interface::tagged { $network_flat_interface:
        base_interface => 'eth1',
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::l3_agent':
        version           => $version,
        dmz_cidr          => $dmz_cidr,
        network_public_ip => $network_public_ip,
        report_interval   => $report_interval,
    }
    contain '::profile::openstack::base::neutron::l3_agent'

    class {'::profile::openstack::base::neutron::linuxbridge_agent':
        version         => $version,
        bridges         => $bridges,
        bridge_mappings => $bridge_mappings,
        report_interval => $report_interval,
    }
    contain '::profile::openstack::base::neutron::linuxbridge_agent'
}
