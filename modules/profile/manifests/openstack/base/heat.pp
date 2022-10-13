# SPDX-License-Identifier: Apache-2.0
#
# Provision the Openstack Heat service
#
# As with all OpenStack services, actually installing the service
#  requres some by-hand steps after the packages and config
#  are set up. Steps are fully enumerated at
#    https://docs.openstack.org/heat/latest/install/install-debian.html
#
#  In brief, the post-puppet steps are:
#
#  - Create database, add accounts and access (the specific access details
#      are added to /etc/heat by puppet)
#  - Create the 'heat' service domain
#  - Create the 'heat' service user and add it to the 'heat' domain
#  - Create service and endpoints in Keystone
#  - Create heat_stack_user and heat_stack_owner roles
#
class profile::openstack::base::heat(
    String $version = lookup('profile::openstack::base::version'),
    Boolean $active = lookup('profile::openstack::base::heat::active'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $internal_auth_port = lookup('profile::openstack::base::keystone::internal_port'),
    String $region = lookup('profile::openstack::base::region'),
    String $db_user = lookup('profile::openstack::base::heat::db_user'),
    String $db_name = lookup('profile::openstack::base::heat::db_name'),
    String $db_pass = lookup('profile::openstack::base::heat::db_pass'),
    String $ldap_user_pass = lookup('profile::openstack::base::heat::service_user_pass'),
    String $domain_admin_pass = lookup('profile::openstack::base::heat::domain_admin_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::heat::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::heat::api_bind_port'),
    Stdlib::Port $cfn_api_bind_port = lookup('profile::openstack::base::heat::api_bind_port'),
    String $rabbit_user = lookup('profile::openstack::base::heat::rabbit_user'),
    String $rabbit_pass = lookup('profile::openstack::base::heat::rabbit_pass'),
    String[32] $auth_encryption_key = lookup('profile::openstack::base::heat::auth_encryption_key'),
    ) {

    $keystone_admin_uri = "https://${keystone_fqdn}:${auth_port}"
    $keystone_internal_uri = "https://${keystone_fqdn}:${internal_auth_port}"

    class { '::openstack::heat::service':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        rabbitmq_nodes        => $rabbitmq_nodes,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_internal_uri => $keystone_internal_uri,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        api_bind_port         => $api_bind_port,
        cfn_api_bind_port     => $cfn_api_bind_port,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_user           => $rabbit_user,
        rabbit_pass           => $rabbit_pass,
        auth_encryption_key   => $auth_encryption_key,
        region                => $region,
        domain_admin_pass     => $domain_admin_pass,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'heat_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (28004) ACCEPT;",
    }

    openstack::db::project_grants { 'heat':
        access_hosts => $openstack_controllers,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
