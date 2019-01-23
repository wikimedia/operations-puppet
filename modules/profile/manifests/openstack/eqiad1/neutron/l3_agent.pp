class profile::openstack::eqiad1::neutron::l3_agent(
    $version = hiera('profile::openstack::eqiad1::version'),
    $bridges = hiera('profile::openstack::eqiad1::neutron::l3_agent_bridges'),
    $bridge_mappings = hiera('profile::openstack::eqiad1::neutron::l3_agent_bridge_mappings'),
    $network_flat_interface_vlan_external = hiera('profile::openstack::eqiad1::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = hiera('profile::openstack::eqiad1::neutron::network_flat_interface_vlan'),
    $network_compat_interface_vlan = hiera('profile::openstack::eqiad1::neutron::network_compat_interface_vlan'),
    $dmz_cidr = hiera('profile::openstack::eqiad1::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::eqiad1::neutron::network_public_ip'),
    $report_interval = hiera('profile::openstack::eqiad1::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::eqiad1::neutron::base_interface'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::neutron::common

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
