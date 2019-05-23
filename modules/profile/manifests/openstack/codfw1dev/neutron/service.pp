class profile::openstack::codfw1dev::neutron::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    ) {

    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::service':
        version         => $version,
    }
    contain '::profile::openstack::base::neutron::service'
}
