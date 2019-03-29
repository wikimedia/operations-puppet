class profile::openstack::codfw1dev::nova::conductor::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
}
