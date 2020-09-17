class profile::openstack::eqiad1::neutron::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    Stdlib::Port $bind_port = lookup('profile::openstack::eqiad1::neutron::bind_port'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::neutron::common
    class {'::profile::openstack::base::neutron::service':
        version   => $version,
        bind_port => $bind_port,
    }
    contain '::profile::openstack::base::neutron::service'
}
