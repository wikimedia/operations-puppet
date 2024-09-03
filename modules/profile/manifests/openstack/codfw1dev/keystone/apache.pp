# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::keystone::apache(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::codfw1dev::keystone::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::codfw1dev::keystone::public_bind_port'),
    String $idp_client_secret = lookup('profile::openstack::codfw1dev::keystone::oidc_secret'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
) {

    class {'::profile::openstack::base::keystone::apache':
        version           => $version,
        admin_bind_port   => $admin_bind_port,
        public_bind_port  => $public_bind_port,
        idp_client_secret => $idp_client_secret,
        keystone_fqdn     => $keystone_fqdn,
    }
}
