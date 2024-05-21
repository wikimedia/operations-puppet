class profile::openstack::eqiad1::neutron::l3_agent(
    $version = lookup('profile::openstack::eqiad1::version'),
    $bridges = lookup('profile::openstack::eqiad1::neutron::l3_agent_bridges'),
    $bridge_mappings = lookup('profile::openstack::eqiad1::neutron::l3_agent_bridge_mappings'),
    $network_flat_interface_vlan_external = lookup('profile::openstack::eqiad1::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = lookup('profile::openstack::eqiad1::neutron::network_flat_interface_vlan'),
    $report_interval = lookup('profile::openstack::eqiad1::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::eqiad1::neutron::base_interface'),
    Optional[Stdlib::MAC] $nic_rename_mac = lookup('profile::openstack::eqiad1::neutron::nic_rename_mac', {default_value => undef}),
    Boolean               $legacy_vlan    = lookup('profile::openstack::eqiad1::neutron::legacy_vlan_naming'),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks_internal = lookup('profile::openstack::eqiad1::neutron::provider_networks_internal', {default_value => {}}),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks_external = lookup('profile::openstack::eqiad1::neutron::provider_networks_external', {default_value => {}}),
    Boolean $use_ovs = lookup('profile::openstack::eqiad1::neutron::use_ovs', {default_value => false}),
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
        legacy_vlan_naming                   => $legacy_vlan,
        interface_driver                     => $use_ovs.bool2str('openvswitch', 'linuxbridge'),
    }
    contain '::profile::openstack::base::neutron::l3_agent'

    if $use_ovs {
        class { 'profile::openstack::base::neutron::ovs_agent':
            version           => $version,
            provider_networks => $provider_networks_internal + $provider_networks_external,
        }
    } else {
        class {'::profile::openstack::base::neutron::linuxbridge_agent':
            version         => $version,
            bridges         => $bridges,
            bridge_mappings => $bridge_mappings,
            report_interval => $report_interval,
        }
        contain '::profile::openstack::base::neutron::linuxbridge_agent'
    }
}
