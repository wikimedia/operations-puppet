class profile::openstack::main::nova::conductor::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    ) {

    require ::profile::openstack::main::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        version         => $version,
        nova_controller => $nova_controller,
    }

    class {'::openstack::nova::conductor::monitor':
        active         => ($::fqdn == $nova_controller),
        critical       => true,
        contact_groups => 'wmcs-team',
    }
    contain '::openstack::nova::conductor::monitor'
}
