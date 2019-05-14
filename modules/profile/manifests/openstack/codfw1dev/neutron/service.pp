class profile::openstack::codfw1dev::neutron::service(
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::codfw1dev::nova_controller'),
    $version = hiera('profile::openstack::codfw1dev::version'),
    ) {

    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
    contain '::profile::openstack::base::neutron::service'
}
