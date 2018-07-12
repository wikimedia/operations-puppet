class profile::openstack::base::neutron::linuxbridge_agent(
    $version = hiera('profile::openstack::base::version'),
    $bridges = hiera('profile::openstack::base::neutron::bridges'),
    $bridge_mappings = hiera('profile::openstack::base::neutron::bridge_mappings'),
    $physical_interface_mappings = hiera('profile::openstack::base::neutron::physical_interface_mappings'),
    $report_interval = hiera('profile::openstack::base::neutron::report_interval'),
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
