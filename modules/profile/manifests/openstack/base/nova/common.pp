# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::nova::common(
    $version = lookup('profile::openstack::base::version'),
    $region = lookup('profile::openstack::base::region'),
    $db_user = lookup('profile::openstack::base::nova::db_user'),
    $db_pass = lookup('profile::openstack::base::nova::db_pass'),
    $db_host = lookup('profile::openstack::base::nova::db_host'),
    $db_name = lookup('profile::openstack::base::nova::db_name'),
    $db_name_api = lookup('profile::openstack::base::nova::db_name_api'),
    $db_name_cell = lookup('profile::openstack::base::nova::db_name_cell'),
    $compute_workers = lookup('profile::openstack::base::nova::compute_workers'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $scheduler_filters = lookup('profile::openstack::base::nova::scheduler_filters'),
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    $rabbit_user = lookup('profile::openstack::base::nova::rabbit_user'),
    $rabbit_pass = lookup('profile::openstack::base::rabbit_pass'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
    $metadata_proxy_shared_secret = lookup('profile::openstack::base::neutron::metadata_proxy_shared_secret'),
    Stdlib::Port $metadata_listen_port = lookup('profile::openstack::base::nova::metadata_listen_port'),
    Stdlib::Port $osapi_compute_listen_port = lookup('profile::openstack::base::nova::osapi_compute_listen_port'),
    Boolean $is_control_node = lookup('profile::openstack::eqiad1::nova::common::is_control_node'),
    ) {

    class {'::openstack::nova::common':
        version                      => $version,
        region                       => $region,
        db_user                      => $db_user,
        db_pass                      => $db_pass,
        db_host                      => $db_host,
        db_name                      => $db_name,
        db_name_api                  => $db_name_api,
        memcached_nodes              => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        rabbitmq_nodes               => $rabbitmq_nodes,
        keystone_fqdn                => $keystone_fqdn,
        scheduler_filters            => $scheduler_filters,
        ldap_user_pass               => $ldap_user_pass,
        rabbit_user                  => $rabbit_user,
        rabbit_pass                  => $rabbit_pass,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        compute_workers              => $compute_workers,
        metadata_listen_port         => $metadata_listen_port,
        osapi_compute_listen_port    => $osapi_compute_listen_port,
        is_control_node              => $is_control_node,
        enforce_policy_scope         => $enforce_policy_scope,
        enforce_new_policy_defaults  => $enforce_new_policy_defaults,
    }
    contain '::openstack::nova::common'

    # TODO: move to the service profile
    openstack::db::project_grants { 'nova_api':
        access_hosts => $haproxy_nodes,
        db_name      => $db_name_api,
        db_user      => $db_user,
        db_pass      => $db_pass,
        project_name => 'nova',
        require      => Package['nova-common'],
    }
    openstack::db::project_grants { 'nova':
        access_hosts => $haproxy_nodes,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
        project_name => 'nova',
        require      => Package['nova-common'],
    }
    openstack::db::project_grants { 'nova_cell':
        access_hosts => $haproxy_nodes,
        db_name      => $db_name_cell,
        db_user      => $db_user,
        db_pass      => $db_pass,
        project_name => 'nova',
        require      => Package['nova-common'],
    }
}
