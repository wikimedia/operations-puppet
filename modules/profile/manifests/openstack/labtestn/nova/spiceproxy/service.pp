class profile::openstack::labtestn::nova::spiceproxy::service(
    $version = hiera('profile::openstack::labtestn::version'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    ) {

    require profile::openstack::labtestn::nova::common
    class {'profile::openstack::base::nova::spiceproxy::service':
        version => $version,
        nova_controller => $nova_controller,
    }
}
