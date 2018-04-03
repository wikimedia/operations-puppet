class profile::openstack::base::neutron::linuxbridge_agent(
    $version = hiera('profile::openstack::base::version'),
    $bridges = hiera('profile::openstack::base::neutron::bridges'),
    $bridge_mappings = hiera('profile::openstack::base::neutron::bridge_mappings'),
    ) {

    class {'::openstack::neutron::linuxbridge_agent':
        version         => $version,
        bridges         => $bridges,
        bridge_mappings => $bridge_mappings,
    }
    contain '::openstack::neutron::linuxbridge_agent'
}
