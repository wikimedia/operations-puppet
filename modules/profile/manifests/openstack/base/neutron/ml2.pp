class profile::openstack::base::neutron::ml2(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'::openstack::neutron::ml2':
        version => $version,
    }
    contain '::openstack::neutron::ml2'
}
