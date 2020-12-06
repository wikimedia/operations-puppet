class profile::openstack::base::cinder(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $public_port = lookup('profile::openstack::base::keystone::public_port'),
    String $db_user = lookup('profile::openstack::base::cinder::db_user'),
    String $db_name = lookup('profile::openstack::base::cinder::db_name'),
    String $db_pass = lookup('profile::openstack::base::cinder::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::cinder::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::cinder::api_bind_port'),
    String $ceph_pool = lookup('profile::openstack::base::cinder::ceph_pool'),
    Boolean $active = lookup('profile::openstack::base::cinder_active'),
    ) {

    $keystone_admin_uri = "http://${keystone_fqdn}:${auth_port}"
    $keystone_public_uri = "http://${keystone_fqdn}:${public_port}"

    class { '::openstack::cinder::service':
        version               => $version,
        active                => $active,
        openstack_controllers => $openstack_controllers,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_public_uri   => $keystone_public_uri,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        api_bind_port         => $api_bind_port,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'cinder_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (8776) ACCEPT;",
    }

    openstack::db::project_grants { 'cinder':
        access_hosts => $openstack_controllers,
        db_name      => 'cinder',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
