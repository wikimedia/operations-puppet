class profile::openstack::codfw1dev::nova::scheduler::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'::profile::openstack::base::nova::scheduler::service':
        version         => $version,
    }
}
