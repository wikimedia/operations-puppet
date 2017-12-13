class profile::openstack::labtest::nova::spiceproxy::service(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::spiceproxy::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
    contain '::profile::openstack::base::nova::spiceproxy::service'
}
