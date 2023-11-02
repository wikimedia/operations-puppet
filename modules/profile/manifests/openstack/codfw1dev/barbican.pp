# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::barbican(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_user = lookup('profile::openstack::codfw1dev::barbican::db_user'),
    String $db_pass = lookup('profile::openstack::codfw1dev::barbican::db_pass'),
    String $db_name = lookup('profile::openstack::codfw1dev::barbican::db_name'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::barbican::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Port $bind_port = lookup('profile::openstack::codfw1dev::barbican::bind_port'),
    String $crypto_kek = lookup('profile::openstack::codfw1dev::barbican::kek'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
) {

    class {'::profile::openstack::base::barbican':
        version                 => $version,
        openstack_control_nodes => $openstack_control_nodes,
        keystone_fqdn           => $keystone_fqdn,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        bind_port               => $bind_port,
        crypto_kek              => $crypto_kek,
        haproxy_nodes           => $haproxy_nodes,
    }
    contain '::profile::openstack::base::barbican'
}
