class profile::openstack::base::keystone::service(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $osm_host = hiera('profile::openstack::base::osm_host'),
    $db_name = hiera('profile::openstack::base::keystone::db_name'),
    $db_user = hiera('profile::openstack::base::keystone::db_user'),
    $db_pass = hiera('profile::openstack::base::keystone::db_pass'),
    $db_host = hiera('profile::openstack::base::keystone::db_host'),
    $token_driver = hiera('profile::openstack::base::keystone::token_driver'),
    $ldap_hosts = hiera('profile::openstack::base::ldap_hosts'),
    $ldap_base_dn = hiera('profile::openstack::base::ldap_base_dn'),
    $ldap_user_id_attribute = hiera('profile::openstack::base::ldap_user_id_attribute'),
    $ldap_user_name_attribute = hiera('profile::openstack::base::ldap_user_name_attribute'),
    $ldap_user_dn = hiera('profile::openstack::base::ldap_user_dn'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $auth_protocol = hiera('profile::openstack::base::keystone::auth_protocol'),
    $auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $public_port = hiera('profile::openstack::base::keystone::public_port'),
    $wiki_status_page_prefix = hiera('profile::openstack::base::keystone::wiki_status_page_prefix'),
    $wiki_status_consumer_token = hiera('profile::openstack::base::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = hiera('profile::openstack::base::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = hiera('profile::openstack::base::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = hiera('profile::openstack::base::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = hiera('profile::openstack::base::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = hiera('profile::openstack::base::keystone::wiki_consumer_secret'),
    $wiki_access_token = hiera('profile::openstack::base::keystone::wiki_access_token'),
    $wiki_access_secret = hiera('profile::openstack::base::keystone::wiki_access_secret'),
    ) {

    class {'openstack2::keystone::service':
        active                      => $::fqdn == $nova_controller,
        version                     => $version,
        nova_controller             => $nova_controller,
        osm_host                    => $osm_host,
        db_name                     => $db_name,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_host                     => $db_host,
        token_driver                => $token_driver,
        ldap_hosts                  => $ldap_hosts,
        ldap_base_dn                => $ldap_base_dn,
        ldap_user_id_attribute      => $ldap_user_id_attribute,
        ldap_user_name_attribute    => $ldap_user_name_attribute,
        ldap_user_dn                => $ldap_user_dn,
        ldap_user_pass              => $ldap_user_pass,
        auth_protocol               => $auth_protocol,
        auth_port                   => $auth_port,
        wiki_status_page_prefix     => $wiki_status_page_prefix,
        wiki_status_consumer_token  => $wiki_status_consumer_token,
        wiki_status_consumer_secret => $wiki_status_consumer_secret,
        wiki_status_access_token    => $wiki_status_access_token,
        wiki_status_access_secret   => $wiki_status_access_secret,
        wiki_consumer_token         => $wiki_consumer_token,
        wiki_consumer_secret        => $wiki_consumer_secret,
        wiki_access_token           => $wiki_access_token,
        wiki_access_secret          => $wiki_access_secret,
    }

    class {'openstack2::keystone::monitor':
        active      => $::fqdn == $nova_controller,
        auth_port   => $auth_port,
        public_port => $public_port,
    }
}
