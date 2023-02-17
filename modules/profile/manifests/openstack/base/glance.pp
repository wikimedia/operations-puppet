# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::glance(
    String $version = lookup('profile::openstack::base::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String $db_user = lookup('profile::openstack::base::glance::db_user'),
    String $db_name = lookup('profile::openstack::base::glance::db_name'),
    String $db_pass = lookup('profile::openstack::base::glance::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::glance::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Absolutepath $glance_data_dir = lookup('profile::openstack::base::glance::data_dir'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::glance::api_bind_port'),
    Array[String] $glance_backends = lookup('profile::openstack::base::glance_backends'),
    String $ceph_pool = lookup('profile::openstack::base::glance::ceph_pool'),
    Boolean $active = lookup('profile::openstack::base::glance_active'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
) {

    class { '::openstack::glance::service':
        version                     => $version,
        active                      => $active,
        keystone_fqdn               => $keystone_fqdn,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_name                     => $db_name,
        db_host                     => $db_host,
        ldap_user_pass              => $ldap_user_pass,
        glance_data_dir             => $glance_data_dir,
        api_bind_port               => $api_bind_port,
        glance_backends             => $glance_backends,
        ceph_pool                   => $ceph_pool,
        memcached_nodes             => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }
    contain '::openstack::glance::service'

    ferm::service { 'glance-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => "@resolve((${haproxy_nodes.join(' ')}))",
    }

    openstack::db::project_grants { 'glance':
        access_hosts => $haproxy_nodes,
        db_name      => 'glance',
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['glance'],
    }
}
