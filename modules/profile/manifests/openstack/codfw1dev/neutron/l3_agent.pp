class profile::openstack::codfw1dev::neutron::l3_agent(
    $version = lookup('profile::openstack::codfw1dev::version'),
    $bridges = lookup('profile::openstack::codfw1dev::neutron::l3_agent_bridges'),
    $bridge_mappings = lookup('profile::openstack::codfw1dev::neutron::l3_agent_bridge_mappings'),
    $network_flat_interface_vlan_external = lookup('profile::openstack::codfw1dev::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = lookup('profile::openstack::codfw1dev::neutron::network_flat_interface_vlan'),
    $report_interval = lookup('profile::openstack::codfw1dev::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::codfw1dev::neutron::base_interface'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    require ::profile::openstack::codfw1dev::neutron::common

    class { 'bridge_utils::workaround_debian_bug_989162': }

    class {'::profile::openstack::base::neutron::l3_agent':
        version                              => $version,
        report_interval                      => $report_interval,
        base_interface                       => $base_interface,
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
