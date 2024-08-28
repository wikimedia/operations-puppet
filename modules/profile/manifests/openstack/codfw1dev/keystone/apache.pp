# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::keystone::apache(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::codfw1dev::keystone::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::codfw1dev::keystone::public_bind_port'),
) {

    class {'::profile::openstack::base::keystone::apache':
        version          => $version,
        admin_bind_port  => $admin_bind_port,
        public_bind_port => $public_bind_port,
    }
}
