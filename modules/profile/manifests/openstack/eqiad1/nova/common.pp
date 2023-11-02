# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::nova::common(
    $version = lookup('profile::openstack::eqiad1::version'),
    $region = lookup('profile::openstack::eqiad1::region'),
    $db_pass = lookup('profile::openstack::eqiad1::nova::db_pass'),
    $db_host = lookup('profile::openstack::eqiad1::nova::db_host'),
    $db_name = lookup('profile::openstack::eqiad1::nova::db_name'),
    $db_name_api = lookup('profile::openstack::eqiad1::nova::db_name_api'),
    $db_name_cell = lookup('profile::openstack::eqiad1::nova::db_name_cell'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    $rabbit_pass = lookup('profile::openstack::eqiad1::nova::rabbit_pass'),
    $metadata_proxy_shared_secret = lookup('profile::openstack::eqiad1::neutron::metadata_proxy_shared_secret'),
    Stdlib::Port $metadata_listen_port = lookup('profile::openstack::eqiad1::nova::metadata_listen_port'),
    Stdlib::Port $osapi_compute_listen_port = lookup('profile::openstack::eqiad1::nova::osapi_compute_listen_port'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::eqiad1::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::eqiad1::keystone::enforce_new_policy_defaults'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::nova::common':
        version                          => $version,
        region                           => $region,
        db_pass                          => $db_pass,
        db_host                          => $db_host,
        db_name                          => $db_name,
        db_name_api                      => $db_name_api,
        db_name_cell                     => $db_name_cell,
        openstack_control_nodes          => $openstack_control_nodes,
        openstack_control_node_interface => 'host_fqdn',
        rabbitmq_nodes                   => $rabbitmq_nodes,
        haproxy_nodes                    => $haproxy_nodes,
        keystone_fqdn                    => $keystone_fqdn,
        ldap_user_pass                   => $ldap_user_pass,
        rabbit_pass                      => $rabbit_pass,
        metadata_listen_port             => $metadata_listen_port,
        metadata_proxy_shared_secret     => $metadata_proxy_shared_secret,
        osapi_compute_listen_port        => $osapi_compute_listen_port,
        enforce_policy_scope             => $enforce_policy_scope,
        enforce_new_policy_defaults      => $enforce_new_policy_defaults,
    }
    contain '::profile::openstack::base::nova::common'
}
