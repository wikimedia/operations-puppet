# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::neutron::linuxbridge_agent(
    $version = lookup('profile::openstack::base::version'),
    $bridges = lookup('profile::openstack::base::neutron::bridges'),
    $bridge_mappings = lookup('profile::openstack::base::neutron::bridge_mappings'),
    $physical_interface_mappings = lookup('profile::openstack::base::neutron::physical_interface_mappings'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    ) {

    class {'::openstack::neutron::linuxbridge_agent':
        version                     => $version,
        bridges                     => $bridges,
        bridge_mappings             => $bridge_mappings,
        physical_interface_mappings => $physical_interface_mappings,
        report_interval             => $report_interval,
    }
    contain '::openstack::neutron::linuxbridge_agent'
}
