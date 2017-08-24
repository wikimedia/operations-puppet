class profile::openstack::labtestn::keystone::service(
    $version = hiera('profile::openstack::labtestn::version'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $osm_host = hiera('profile::openstack::labtestn::osm_host'),
    $db_host = hiera('profile::openstack::labtestn::keystone::db_host'),
    $token_driver = hiera('profile::openstack::labtestn::keystone::token_driver'),
    $db_pass = hiera('profile::openstack::labtestn::keystone::db_pass'),
    $ldap_hosts = hiera('profile::openstack::labtestn::ldap_hosts'),
    $ldap_user_pass = hiera('profile::openstack::labtestn::ldap_user_pass'),
    $wiki_status_consumer_token = hiera('profile::openstack::labtestn::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = hiera('profile::openstack::labtestn::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = hiera('profile::openstack::labtestn::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = hiera('profile::openstack::labtestn::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = hiera('profile::openstack::labtestn::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = hiera('profile::openstack::labtestn::keystone::wiki_consumer_secret'),
    $wiki_access_token = hiera('profile::openstack::labtestn::keystone::wiki_access_token'),
    $wiki_access_secret = hiera('profile::openstack::labtestn::keystone::wiki_access_secret'),
    ) {

    package {'mysql-server':
        ensure => present,
    }

    require profile::openstack::labtestn::clientlib
    class {'profile::openstack::base::keystone::service':
        version                     => $version,
        nova_controller             => $nova_controller,
        osm_host                    => $osm_host,
        db_host                     => $db_host,
        token_driver                => $token_driver,
        db_pass                     => $db_pass,
        ldap_hosts                  => $ldap_hosts,
        ldap_user_pass              => $ldap_user_pass,
        wiki_status_consumer_token  => $wiki_status_consumer_token,
        wiki_status_consumer_secret => $wiki_status_consumer_secret,
        wiki_status_access_token    => $wiki_status_access_token,
        wiki_status_access_secret   => $wiki_status_access_secret,
        wiki_consumer_token         => $wiki_consumer_token,
        wiki_consumer_secret        => $wiki_consumer_secret,
        wiki_access_token           => $wiki_access_token,
        wiki_access_secret          => $wiki_access_secret,
        require                     => Package['mysql-server'],
    }

    class {'profile::openstack::base::keystone::hooks':
        version => $version,
    }
}
