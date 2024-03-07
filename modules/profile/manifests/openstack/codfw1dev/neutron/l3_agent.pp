# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::neutron::l3_agent(
    $version = lookup('profile::openstack::codfw1dev::version'),
    $bridges = lookup('profile::openstack::codfw1dev::neutron::l3_agent_bridges'),
    $bridge_mappings = lookup('profile::openstack::codfw1dev::neutron::l3_agent_bridge_mappings'),
    $network_flat_interface_vlan_external = lookup('profile::openstack::codfw1dev::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = lookup('profile::openstack::codfw1dev::neutron::network_flat_interface_vlan'),
    $report_interval = lookup('profile::openstack::codfw1dev::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::codfw1dev::neutron::base_interface'),
    Boolean $legacy_vlan_naming    = lookup('profile::openstack::codfw1dev::neutron::legacy_vlan_naming'),
    Boolean $use_ovs = lookup('profile::openstack::codfw1dev::neutron::use_ovs', {default_value => false}),
) {
    require ::profile::openstack::codfw1dev::clientpackages
    require ::profile::openstack::codfw1dev::neutron::common

    # Enable IPv6 in physical interfaces of vlan ports
    ensure_packages(['bridge-utils'])
    if debian::codename::eq('bullseye') {
      # Bullseye needs a workaround
      class { 'bridge_utils::workaround_debian_bug_989162': }
    } else {
      # Later versions support setting this in a config file
      file_line { 'bridge_ipv6':
        ensure => present,
        path   => '/etc/default/bridge-utils',
        line   => 'BRIDGE_DISABLE_LINKLOCAL_IPV6_ALSO_PHYS=no',
        match  => 'BRIDGE_DISABLE_LINKLOCAL_IPV6_ALSO_PHYS',
      }
    }

    class {'::profile::openstack::base::neutron::l3_agent':
        version                              => $version,
        report_interval                      => $report_interval,
        base_interface                       => $base_interface,
        network_flat_interface_vlan          => $network_flat_interface_vlan,
        network_flat_interface_vlan_external => $network_flat_interface_vlan_external,
        legacy_vlan_naming                   => $legacy_vlan_naming,
        interface_driver                     => $use_ovs.bool2str('openvswitch', 'linuxbridge'),
    }
    contain '::profile::openstack::base::neutron::l3_agent'

    if $use_ovs {
        class { 'profile::openstack::base::neutron::ovs_agent':
            version => $version,
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
