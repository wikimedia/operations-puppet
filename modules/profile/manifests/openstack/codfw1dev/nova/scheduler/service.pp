class profile::openstack::codfw1dev::nova::scheduler::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'::profile::openstack::base::nova::scheduler::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
}
