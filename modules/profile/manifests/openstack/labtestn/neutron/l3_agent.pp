class profile::openstack::labtestn::neutron::l3_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $bridges = hiera('profile::openstack::labtestn::neutron::l3_agent_bridges'),
    $bridge_mappings = hiera('profile::openstack::labtestn::neutron::l3_agent_bridge_mappings'),
    $network_flat_interface_vlan_external = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_flat_interface_vlan'),
    $dmz_cidr = hiera('profile::openstack::labtestn::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::labtestn::neutron::network_public_ip'),
    $report_interval = hiera('profile::openstack::labtestn::neutron::report_interval'),
    $network_compat_interface_vlan = hiera('profile::openstack::labtestn::neutron::network_compat_interface_vlan'),
    $base_interface = lookup('profile::openstack::labtestn::neutron::base_interface'),
    ) {

    require ::profile::openstack::labtestn::clientpackages
    require ::profile::openstack::labtestn::neutron::common

    class {'::profile::openstack::base::neutron::l3_agent':
        version                              => $version,
        dmz_cidr                             => $dmz_cidr,
        network_public_ip                    => $network_public_ip,
        report_interval                      => $report_interval,
        base_interface                       => $base_interface,
        network_compat_interface_vlan        => $network_compat_interface_vlan,
        network_flat_interface_vlan          => $network_flat_interface_vlan,
        network_flat_interface_vlan_external => $network_flat_interface_vlan_external,
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
