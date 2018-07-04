class profile::openstack::eqiad1::nova::conductor::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
}
