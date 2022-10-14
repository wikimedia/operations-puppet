# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::magnum(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::codfw1dev::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::codfw1dev::magnum::db_pass'),
    String $db_user = lookup('profile::openstack::codfw1dev::magnum::db_host'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::magnum::db_host'),
    String $db_name = lookup('profile::openstack::codfw1dev::magnum::db_name'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::magnum::api_bind_port'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::magnum::service_user_pass'),
    String $rabbit_pass = lookup('profile::openstack::codfw1dev::magnum::rabbit_pass'),
    String $region = lookup('profile::openstack::codfw1dev::region'),
    String $domain_admin_pass = lookup('profile::openstack::codfw1dev::magnum::domain_admin_pass'),
) {
    class {'::profile::openstack::base::magnum':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        rabbitmq_nodes        => $rabbitmq_nodes,
        keystone_fqdn         => $keystone_fqdn,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_host               => $db_host,
        db_name               => $db_name,
        api_bind_port         => $api_bind_port,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_pass           => $rabbit_pass,
        region                => $region,
        domain_admin_pass     => $domain_admin_pass,
    }
}
