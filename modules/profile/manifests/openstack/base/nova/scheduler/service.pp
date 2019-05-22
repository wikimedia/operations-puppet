class profile::openstack::base::nova::scheduler::service(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'::openstack::nova::scheduler::service':
        active  => true,
        version => $version,
    }
    contain '::openstack::nova::scheduler::service'
}
