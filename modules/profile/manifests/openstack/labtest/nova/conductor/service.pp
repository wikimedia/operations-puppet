class profile::openstack::labtest::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        nova_controller => $nova_controller,
    }
    contain '::profile::openstack::base::nova::conductor::service'

    class {'::openstack::nova::conductor::monitor':
        active         => ($::fqdn == $nova_controller),
        critical       => true,
        contact_groups => 'wmcs-team',
    }
    contain '::openstack::nova::conductor::monitor'
}
