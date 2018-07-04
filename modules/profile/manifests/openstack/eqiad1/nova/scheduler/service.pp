class profile::openstack::eqiad1::nova::scheduler::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'::profile::openstack::base::nova::scheduler::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
}
