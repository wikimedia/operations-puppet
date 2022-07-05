# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::heat(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::codfw1dev::heat::db_pass'),
    String $db_user = lookup('profile::openstack::codfw1dev::heat::db_host'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::heat::db_host'),
    String $db_name = lookup('profile::openstack::codfw1dev::heat::db_name'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::heat::api_bind_port'),
    Stdlib::Port $cfn_api_bind_port = lookup('profile::openstack::codfw1dev::heat::cfn_api_bind_port'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::heat::service_user_pass'),
    String $rabbit_pass = lookup('profile::openstack::codfw1dev::nova::rabbit_pass'),
    String $domain_admin_pass = lookup('profile::openstack::codfw1dev::heat::domain_admin_pass'),
    String $region = lookup('profile::openstack::codfw1dev::region'),
    String[32] $auth_encryption_key = lookup('profile::openstack::codfw1dev::heat::auth_encryption_key'),
) {
    class {'::profile::openstack::base::heat':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        keystone_fqdn         => $keystone_fqdn,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_host               => $db_host,
        db_name               => $db_name,
        api_bind_port         => $api_bind_port,
        cfn_api_bind_port     => $cfn_api_bind_port,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_pass           => $rabbit_pass,
        region                => $region,
        auth_encryption_key   => $auth_encryption_key,
        domain_admin_pass     => $domain_admin_pass,
    }
}
