class profile::openstack::base::neutron::service(
    $version = hiera('profile::openstack::base::version'),
    ) {
    class {'::openstack::neutron::service':
        version => $version,
    }
    contain '::openstack::neutron::service'
}
