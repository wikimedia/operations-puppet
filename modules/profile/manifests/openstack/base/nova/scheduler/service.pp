class profile::openstack::base::nova::scheduler::service(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    ) {

    class {'::openstack2::nova::scheduler::service':
        active  => ($::fqdn == $nova_controller),
        version => $version,
    }
}
