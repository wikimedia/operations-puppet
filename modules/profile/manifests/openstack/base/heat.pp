# SPDX-License-Identifier: Apache-2.0

class profile::openstack::base::heat(
    String $version = lookup('profile::openstack::base::version'),
    Boolean $active = lookup('profile::openstack::codfw1dev::heat::active'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    String $region = lookup('profile::openstack::base::region'),
    String $db_user = lookup('profile::openstack::base::heat::db_user'),
    String $db_name = lookup('profile::openstack::base::heat::db_name'),
    String $db_pass = lookup('profile::openstack::base::heat::db_pass'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::heat::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::heat::api_bind_port'),
    Stdlib::Port $cfn_api_bind_port = lookup('profile::openstack::base::heat::api_bind_port'),
    String $rabbit_user = lookup('profile::openstack::base::nova::rabbit_user'),
    String $rabbit_pass = lookup('profile::openstack::base::nova::rabbit_pass'),
    ) {

    $keystone_admin_uri = "https://${keystone_fqdn}:${auth_port}"

    class { '::openstack::heat::service':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        keystone_admin_uri    => $keystone_admin_uri,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        api_bind_port         => $api_bind_port,
        cfn_api_bind_port     => $cfn_api_bind_port,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_user           => $rabbit_user,
        rabbit_pass           => $rabbit_pass,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'heat_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (8004 28004) ACCEPT;",
    }

    openstack::db::project_grants { 'heat':
        access_hosts => $openstack_controllers,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
