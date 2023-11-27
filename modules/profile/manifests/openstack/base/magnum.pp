# SPDX-License-Identifier: Apache-2.0

class profile::openstack::base::magnum(
    String $version = lookup('profile::openstack::base::version'),
    Boolean $active = lookup('profile::openstack::base::magnum::active'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String $region = lookup('profile::openstack::base::region'),
    String $db_user = lookup('profile::openstack::base::magnum::db_user'),
    String $db_name = lookup('profile::openstack::base::magnum::db_name'),
    String $db_pass = lookup('profile::openstack::base::magnum::db_pass'),
    String $ldap_user_pass = lookup('profile::openstack::base::magnum::service_user_pass'),
    String $domain_admin_pass = lookup('profile::openstack::base::magnum::domain_admin_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::magnum::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::magnum::api_bind_port'),
    String $rabbit_user = lookup('profile::openstack::base::magnum::rabbit_user'),
    String $rabbit_pass = lookup('profile::openstack::base::magnum::rabbit_pass'),
    Stdlib::Fqdn $etcd_discovery_host = lookup('profile::openstack::base::magnum::etcd_discovery_host'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
) {
    class { '::openstack::magnum::service':
        version                     => $version,
        memcached_nodes             => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        rabbitmq_nodes              => $rabbitmq_nodes,
        keystone_fqdn               => $keystone_fqdn,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_name                     => $db_name,
        db_host                     => $db_host,
        etcd_discovery_host         => $etcd_discovery_host,
        api_bind_port               => $api_bind_port,
        ldap_user_pass              => $ldap_user_pass,
        rabbit_user                 => $rabbit_user,
        rabbit_pass                 => $rabbit_pass,
        region                      => $region,
        domain_admin_pass           => $domain_admin_pass,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }

    ferm::service { 'magnum-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => $haproxy_nodes,
    }

    openstack::db::project_grants { 'magnum':
        access_hosts => $haproxy_nodes,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['magnum-api'],
    }
}
