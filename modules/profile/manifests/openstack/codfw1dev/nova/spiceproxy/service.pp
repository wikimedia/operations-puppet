class profile::openstack::codfw1dev::nova::spiceproxy::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'::profile::openstack::base::nova::spiceproxy::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
}
