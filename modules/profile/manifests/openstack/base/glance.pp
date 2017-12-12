class profile::openstack::base::glance(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::base::nova_controller_stanbdy'),
    $auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $public_port = hiera('profile::openstack::base::keystone::public_port'),
    $db_user = hiera('profile::openstack::base::glance::db_user'),
    $db_name = hiera('profile::openstack::base::glance::db_name'),
    $db_pass = hiera('profile::openstack::base::glance::db_pass'),
    $db_host = hiera('profile::openstack::base::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $glance_data = hiera('profile::openstack::base::glance::data_dir'),
    $glance_image_dir = hiera('profile::openstack::base::glance::image_dir'),
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    ) {

    $keystone_admin_uri = "http://${nova_controller}:${auth_port}"
    $keystone_public_uri = "http://${nova_controller}:${public_port}"

    class { '::openstack::glance::service':
        version                 => $version,
        active                  => $::fqdn == $nova_controller,
        keystone_admin_uri      => $keystone_admin_uri,
        keystone_public_uri     => $keystone_public_uri,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        nova_controller_standby => $nova_controller_standby,
        glance_data             => $glance_data,
        glance_image_dir        => $glance_image_dir,
    }
    contain '::openstack::glance::service'

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'glance_registry_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (9292) ACCEPT;",
    }

    # XXX: seems dupe of glance_registry_all?
    ferm::rule{'glance-registry-labs-hosts':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range} proto tcp dport 9292 ACCEPT;",
    }

    # This is a no-op on the primary controller; on the spare master
    #  it allows us to sync up glance images with rsync.
    ferm::rule{'glancesync':
        ensure => 'present',
        rule   => "saddr @resolve(${nova_controller}) proto tcp dport (ssh) ACCEPT;",
    }
}
