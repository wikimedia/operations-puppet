class profile::openstack::eqiad1::neutron::l3_agent(
    $version = lookup('profile::openstack::eqiad1::version'),
    $bridges = lookup('profile::openstack::eqiad1::neutron::l3_agent_bridges'),
    $bridge_mappings = lookup('profile::openstack::eqiad1::neutron::l3_agent_bridge_mappings'),
    Network::VLANTag $network_flat_interface_vlan_external = lookup('profile::openstack::eqiad1::neutron::network_flat_interface_vlan_external'),
    Network::VLANTag $network_flat_interface_vlan = lookup('profile::openstack::eqiad1::neutron::network_flat_interface_vlan'),
    $report_interval = lookup('profile::openstack::eqiad1::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::eqiad1::neutron::base_interface'),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks_internal = lookup('profile::openstack::eqiad1::neutron::provider_networks_internal', {default_value => {}}),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks_external = lookup('profile::openstack::eqiad1::neutron::provider_networks_external', {default_value => {}}),
) {
    require ::profile::openstack::eqiad1::neutron::common

    class {'::profile::openstack::base::neutron::l3_agent':
        version                              => $version,
        report_interval                      => $report_interval,
        base_interface                       => $base_interface,
        network_flat_interface_vlan          => $network_flat_interface_vlan,
        network_flat_interface_vlan_external => $network_flat_interface_vlan_external,
    }
    contain '::profile::openstack::base::neutron::l3_agent'

    class { 'profile::openstack::base::neutron::ovs_agent':
        version           => $version,
        provider_networks => $provider_networks_internal + $provider_networks_external,
    }
}
