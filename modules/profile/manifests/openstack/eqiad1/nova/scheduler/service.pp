class profile::openstack::eqiad1::nova::scheduler::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'::profile::openstack::base::nova::scheduler::service':
        version         => $version,
    }
}
