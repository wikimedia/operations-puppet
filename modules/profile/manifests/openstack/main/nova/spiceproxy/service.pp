class profile::openstack::main::nova::spiceproxy::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    ) {

    require profile::openstack::main::nova::common
    class {'profile::openstack::base::nova::spiceproxy::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
}
