class profile::openstack::codfw1dev::neutron::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Port $bind_port = lookup('profile::openstack::codfw1dev::neutron::bind_port'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::service':
        version       => $version,
        bind_port     => $bind_port,
        haproxy_nodes => $haproxy_nodes,
    }
    contain '::profile::openstack::base::neutron::service'
}
