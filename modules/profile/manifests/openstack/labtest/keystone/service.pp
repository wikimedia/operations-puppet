class profile::openstack::labtest::keystone::service(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $keystone_host = hiera('profile::openstack::labtest::keystone_host'),
    $osm_host = hiera('profile::openstack::labtest::osm_host'),
    $db_host = hiera('profile::openstack::labtest::keystone::db_host'),
    $token_driver = hiera('profile::openstack::labtest::keystone::token_driver'),
    $db_pass = hiera('profile::openstack::labtest::keystone::db_pass'),
    $nova_db_pass = hiera('profile::openstack::labtest::nova::db_pass'),
    $ldap_hosts = hiera('profile::openstack::labtest::ldap_hosts'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $wiki_status_consumer_token = hiera('profile::openstack::labtest::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = hiera('profile::openstack::labtest::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = hiera('profile::openstack::labtest::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = hiera('profile::openstack::labtest::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = hiera('profile::openstack::labtest::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = hiera('profile::openstack::labtest::keystone::wiki_consumer_secret'),
    $wiki_access_token = hiera('profile::openstack::labtest::keystone::wiki_access_token'),
    $wiki_access_secret = hiera('profile::openstack::labtest::keystone::wiki_access_secret'),
    $labs_hosts_range = hiera('profile::openstack::labtest::labs_hosts_range'),
    $nova_controller_standby = hiera('profile::openstack::labtest::nova_controller_standby'),
    $nova_api_host = hiera('profile::openstack::labtest::nova_api_host'),
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    $designate_host_standby = hiera('profile::openstack::labtest::designate_host_standby'),
    $second_region_designate_host = hiera('profile::openstack::labtest::second_region_designate_host'),
    $labweb_hosts = hiera('profile::openstack::labtest::labweb_hosts'),
    $puppetmaster_hostname = hiera('profile::openstack::labtest::puppetmaster_hostname'),
    $auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $public_port = hiera('profile::openstack::base::keystone::public_port'),
    $labtestn_nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $labtestn_nova_controller_standby = hiera('profile::openstack::labtestn::nova_controller_standby'),
    ) {

    #
    # not having keystone service since the daemon runs on labtestn, while the
    # database does lives here (by now)
    #

    class{'::profile::openstack::base::keystone::db':
        labs_hosts_range             => $labs_hosts_range,
        puppetmaster_hostname        => $puppetmaster_hostname,
        designate_host               => $designate_host,
        second_region_designate_host => $second_region_designate_host,
        osm_host                     => $osm_host,
    }
    contain '::profile::openstack::base::keystone::db'

    require ::profile::openstack::labtest::clientpackages

    # Since the DB for keystone is local and we want keystone
    # in the other codfw deployment to access we add this rule
    ferm::rule{'keystone_for_cross_region':
        ensure => 'present',
        rule   => "saddr (@resolve(${labtestn_nova_controller}) @resolve(${labtestn_nova_controller}, AAAA)
                          @resolve(${labtestn_nova_controller_standby}) @resolve(${labtestn_nova_controller_standby}, AAAA)
                          ) proto tcp dport (3306) ACCEPT;",
    }
}

