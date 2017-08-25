class profile::openstack::main::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    ) {

    require ::profile::openstack::main::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        nova_controller => $nova_controller,
    }

    class {'::openstack2::nova::conductor::monitor':
        active => ($::fqdn == $nova_controller),
    }
}
