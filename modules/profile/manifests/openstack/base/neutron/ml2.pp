class profile::openstack::base::neutron::ml2(
    $version = hiera('profile::openstack::base::version'),
    $network_flat_interface = hiera('profile::openstack::base::neutron::network_flat_interface'),
    ) {

    class {'::openstack::neutron::ml2':
        version                => $version,
        network_flat_interface => $network_flat_interface,
    }
    contain '::openstack::neutron::ml2'
}
