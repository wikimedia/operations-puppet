class profile::openstack::base::placement(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $public_port = lookup('profile::openstack::base::keystone::public_port'),
    String $db_user = lookup('profile::openstack::base::placement::db_user'),
    String $db_name = lookup('profile::openstack::base::placement::db_name'),
    String $db_pass = lookup('profile::openstack::base::placement::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::placement::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::placement::api_bind_port'),
    ) {

    $keystone_admin_uri = "https://${keystone_fqdn}:${auth_port}"
    $keystone_public_uri = "https://${keystone_fqdn}:${public_port}"

    class { '::openstack::placement::service':
        openstack_controllers => $openstack_controllers,
        version               => $version,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_public_uri   => $keystone_public_uri,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        ldap_user_pass        => $ldap_user_pass,
        api_bind_port         => $api_bind_port,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'placement_ha_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (28778) ACCEPT;",
    }

    ferm::rule {'placement_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (28778) ACCEPT;",
    }

    openstack::db::project_grants { 'placement':
        access_hosts => $openstack_controllers,
        db_name      => 'placement',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
