class profile::openstack::labtestn::neutron::l3_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $network_flat_interface_external = hiera('profile::openstack::labtestn::neutron::network_flat_interface_external'),
    $network_flat_interface_external_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_external_vlan'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan'),
    $network_flat_interface = hiera('profile::openstack::labtestn::neutron::network_flat_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan'),
    $network_flat_name = hiera('profile::openstack::labtestn::neutron::network_flat_name'),
    $dmz_cidr = hiera('profile::openstack::labtestn::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::labtestn::neutron::network_public_ip'),
    $internal_bridge = hiera('profile::openstack::labtestn::neutron::internal_bridge'),
    $external_bridge = hiera('profile::openstack::labtestn::neutron::external_bridge'),
    ) {

    # Create interface for flat external
    # labtestn is using a subinterface here
    interface::tagged { $network_flat_interface_external:
        base_interface => 'eth1',
        vlan_id        => $network_flat_interface_external_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::linuxbridge_agent':
        version                => $version,
        network_flat_interface => $network_flat_interface,
        internal_bridge        => $internal_bridge,
        bridge_mappings        => "${internal_bridge}:${internal_bridge},${external_bridge}:${external_bridge}",
    }
    contain '::profile::openstack::base::neutron::linuxbridge_agent'

    class {'::profile::openstack::base::neutron::l3_agent':
        version            => $version,
        dmz_cidr           => $dmz_cidr,
        external_bridge    => $external_bridge,
        bridge_addif       => $network_flat_interface_external,
        network_public_ip  => $network_public_ip,
        require            => Class['::profile::openstack::base::neutron::linuxbridge_agent'],
    }
    contain '::profile::openstack::base::neutron::l3_agent'
}
