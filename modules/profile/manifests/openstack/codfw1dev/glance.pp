# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::glance(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::codfw1dev::glance::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::glance::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::glance::api_bind_port'),
    String $ceph_pool = lookup('profile::openstack::codfw1dev::glance::ceph_pool'),
    Array[String] $glance_backends = lookup('profile::openstack::codfw1dev::glance_backends'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::codfw1dev::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::codfw1dev::keystone::enforce_new_policy_defaults'),
) {

    class {'::profile::openstack::base::glance':
        version                     => $version,
        openstack_control_nodes     => $openstack_control_nodes,
        keystone_fqdn               => $keystone_fqdn,
        db_pass                     => $db_pass,
        db_host                     => $db_host,
        ldap_user_pass              => $ldap_user_pass,
        api_bind_port               => $api_bind_port,
        glance_backends             => $glance_backends,
        ceph_pool                   => $ceph_pool,
        active                      => true,
        haproxy_nodes               => $haproxy_nodes,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }
    contain '::profile::openstack::base::glance'
}
