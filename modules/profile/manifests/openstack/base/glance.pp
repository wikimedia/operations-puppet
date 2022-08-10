class profile::openstack::base::glance(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $public_port = lookup('profile::openstack::base::keystone::public_port'),
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
    ) {

    $keystone_admin_uri = "https://${keystone_fqdn}:${auth_port}"
    $keystone_public_uri = "https://${keystone_fqdn}:${public_port}"

    class { '::openstack::glance::service':
        version             => $version,
        active              => $active,
        keystone_admin_uri  => $keystone_admin_uri,
        keystone_public_uri => $keystone_public_uri,
        db_user             => $db_user,
        db_pass             => $db_pass,
        db_name             => $db_name,
        db_host             => $db_host,
        ldap_user_pass      => $ldap_user_pass,
        glance_data_dir     => $glance_data_dir,
        api_bind_port       => $api_bind_port,
        glance_backends     => $glance_backends,
        ceph_pool           => $ceph_pool,
    }
    contain '::openstack::glance::service'

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'glance_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (9292 29292) ACCEPT;",
    }

    openstack::db::project_grants { 'glance':
        access_hosts => $openstack_controllers,
        db_name      => 'glance',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
