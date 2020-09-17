class profile::openstack::codfw1dev::neutron::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Port $bind_port = lookup('profile::openstack::codfw1dev::neutron::bind_port'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::service':
        version   => $version,
        bind_port => $bind_port,
    }
    contain '::profile::openstack::base::neutron::service'
}
