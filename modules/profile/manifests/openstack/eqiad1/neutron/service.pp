class profile::openstack::eqiad1::neutron::service(
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::eqiad1::nova_controller'),
    $version = hiera('profile::openstack::eqiad1::version'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::neutron::common
    class {'::profile::openstack::base::neutron::service':
        version         => $version,
        nova_controller => $nova_controller,
    }
    contain '::profile::openstack::base::neutron::service'
}
