class profile::openstack::eqiad1::neutron::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    ) {

    require ::profile::openstack::eqiad1::clientlib
    require ::profile::openstack::eqiad1::neutron::common
    class {'::profile::openstack::base::neutron::service':
        version => $version,
    }
    contain '::profile::openstack::base::neutron::service'
}
