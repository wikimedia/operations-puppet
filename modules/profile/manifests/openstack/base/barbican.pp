class profile::openstack::base::barbican(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $public_port = lookup('profile::openstack::base::keystone::public_port'),
    String $db_user = lookup('profile::openstack::base::barbican::db_user'),
    String $db_name = lookup('profile::openstack::base::barbican::db_name'),
    String $db_pass = lookup('profile::openstack::base::barbican::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::barbican::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Port $bind_port = lookup('profile::openstack::base::barbican::bind_port'),
    String $crypto_kek = lookup('profile::openstack::base::barbican::kek'),
    ) {

    $keystone_admin_uri = "https://${keystone_fqdn}:${auth_port}"
    $keystone_public_uri = "https://${keystone_fqdn}:${public_port}"

    class { '::openstack::barbican::service':
        version             => $version,
        keystone_admin_uri  => $keystone_admin_uri,
        keystone_public_uri => $keystone_public_uri,
        db_user             => $db_user,
        db_pass             => $db_pass,
        crypto_kek          => $crypto_kek,
        db_name             => $db_name,
        db_host             => $db_host,
        ldap_user_pass      => $ldap_user_pass,
        bind_port           => $bind_port,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'barbican_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (2${bind_port}) ACCEPT;",
    }

    openstack::db::project_grants { 'barbican':
        access_hosts => $openstack_controllers,
        db_name      => 'barbican',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
