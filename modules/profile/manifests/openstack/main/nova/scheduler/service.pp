class profile::openstack::main::nova::scheduler::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    ) {

    require profile::openstack::main::nova::common
    class {'profile::openstack::base::nova::scheduler::service':
        version         => $version,
        nova_controller => $nova_controller,
    }

    class {'openstack2::nova::scheduler::monitor':
        active => $::fqdn == $nova_controller,
    }
}
