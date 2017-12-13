class profile::openstack::labtest::nova::scheduler::service(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::scheduler::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
    contain '::profile::openstack::base::nova::scheduler::service'

    class {'::openstack::nova::scheduler::monitor':
        active => ($::fqdn == $nova_controller),
    }
    contain '::openstack::nova::scheduler::monitor'
}
