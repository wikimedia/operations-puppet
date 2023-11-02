# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::placement(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::codfw1dev::placement::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::placement::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::placement::api_bind_port'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
) {
    class {'::profile::openstack::base::placement':
        version                 => $version,
        openstack_control_nodes => $openstack_control_nodes,
        keystone_fqdn           => $keystone_fqdn,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        api_bind_port           => $api_bind_port,
        haproxy_nodes           => $haproxy_nodes,
    }
    contain '::profile::openstack::base::placement'
}
