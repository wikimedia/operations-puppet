class profile::openstack::eqiad1::neutron::l3_agent(
    $version = lookup('profile::openstack::eqiad1::version'),
    $bridges = lookup('profile::openstack::eqiad1::neutron::l3_agent_bridges'),
    $bridge_mappings = lookup('profile::openstack::eqiad1::neutron::l3_agent_bridge_mappings'),
    $network_flat_interface_vlan_external = lookup('profile::openstack::eqiad1::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = lookup('profile::openstack::eqiad1::neutron::network_flat_interface_vlan'),
    $report_interval = lookup('profile::openstack::eqiad1::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::eqiad1::neutron::base_interface'),
    Optional[Stdlib::MAC] $nic_rename_mac = lookup('profile::openstack::eqiad1::neutron::nic_rename_mac', {default_value => undef}),
    ) {

    if $nic_rename_mac {
        interface::rename { $base_interface:
            mac => $nic_rename_mac,
        }
    }

    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::neutron::common

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
