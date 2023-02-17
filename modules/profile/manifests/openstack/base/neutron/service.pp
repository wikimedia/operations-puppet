# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::neutron::service(
    $version = lookup('profile::openstack::base::version'),
    Stdlib::Port $bind_port = lookup('profile::openstack::base::neutron::bind_port'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
) {
    class {'::openstack::neutron::service':
        version   => $version,
        active    => true,
        bind_port => $bind_port,
    }
    contain '::openstack::neutron::service'

    ferm::service { 'neutron-api-backend':
        proto  => 'tcp',
        port   => $bind_port,
        srange => "@resolve((${haproxy_nodes.join(' ')}))",
    }
}
