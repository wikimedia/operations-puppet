class profile::openstack::eqiad1::nova::conductor::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        version         => $version,
    }
}
