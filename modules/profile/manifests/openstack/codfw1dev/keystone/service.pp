class profile::openstack::codfw1dev::keystone::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $region = hiera('profile::openstack::codfw1dev::region'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $osm_host = hiera('profile::openstack::codfw1dev::osm_host'),
    $db_host = hiera('profile::openstack::codfw1dev::keystone::db_host'),
    $token_driver = hiera('profile::openstack::codfw1dev::keystone::token_driver'),
    $db_pass = hiera('profile::openstack::codfw1dev::keystone::db_pass'),
    $nova_db_pass = hiera('profile::openstack::codfw1dev::nova::db_pass'),
    $ldap_hosts = hiera('profile::openstack::codfw1dev::ldap_hosts'),
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $wiki_status_consumer_token = hiera('profile::openstack::codfw1dev::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = hiera('profile::openstack::codfw1dev::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = hiera('profile::openstack::codfw1dev::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = hiera('profile::openstack::codfw1dev::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = hiera('profile::openstack::codfw1dev::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = hiera('profile::openstack::codfw1dev::keystone::wiki_consumer_secret'),
    $wiki_access_token = hiera('profile::openstack::codfw1dev::keystone::wiki_access_token'),
    $wiki_access_secret = hiera('profile::openstack::codfw1dev::keystone::wiki_access_secret'),
    $labs_hosts_range = hiera('profile::openstack::codfw1dev::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::codfw1dev::labs_hosts_range_v6'),
    $nova_controller_standby = hiera('profile::openstack::codfw1dev::nova_controller_standby'),
    $nova_api_host = hiera('profile::openstack::codfw1dev::nova_api_host'),
    $designate_host = hiera('profile::openstack::codfw1dev::designate_host'),
    $designate_host_standby = hiera('profile::openstack::codfw1dev::designate_host_standby'),
    $second_region_designate_host = hiera('profile::openstack::codfw1dev::second_region_designate_host'),
    $second_region_designate_host_standby = hiera('profile::openstack::codfw1dev::second_region_designate_host_standby'),
    $labweb_hosts = hiera('profile::openstack::codfw1dev::labweb_hosts'),
    $puppetmaster_hostname = hiera('profile::openstack::codfw1dev::puppetmaster_hostname'),
    $auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $public_port = hiera('profile::openstack::base::keystone::public_port'),
    ) {

    class{'::profile::openstack::base::keystone::db':
        labs_hosts_range             => $labs_hosts_range,
        labs_hosts_range_v6          => $labs_hosts_range_v6,
        puppetmaster_hostname        => $puppetmaster_hostname,
        designate_host               => $designate_host,
        second_region_designate_host => $second_region_designate_host,
        osm_host                     => $osm_host,
    }
    contain '::profile::openstack::base::keystone::db'

    require ::profile::openstack::codfw1dev::clientpackages
    class {'::profile::openstack::base::keystone::service':
        version                              => $version,
        region                               => $region,
        nova_controller                      => $nova_controller,
        keystone_host                        => $keystone_host,
        osm_host                             => $osm_host,
        db_host                              => $db_host,
        token_driver                         => $token_driver,
        db_pass                              => $db_pass,
        nova_db_pass                         => $nova_db_pass,
        ldap_hosts                           => $ldap_hosts,
        ldap_user_pass                       => $ldap_user_pass,
        wiki_status_consumer_token           => $wiki_status_consumer_token,
        wiki_status_consumer_secret          => $wiki_status_consumer_secret,
        wiki_status_access_token             => $wiki_status_access_token,
        wiki_status_access_secret            => $wiki_status_access_secret,
        wiki_consumer_token                  => $wiki_consumer_token,
        wiki_consumer_secret                 => $wiki_consumer_secret,
        wiki_access_token                    => $wiki_access_token,
        wiki_access_secret                   => $wiki_access_secret,
        labs_hosts_range                     => $labs_hosts_range,
        labs_hosts_range_v6                  => $labs_hosts_range_v6,
        nova_controller_standby              => $nova_controller_standby,
        nova_api_host                        => $nova_api_host,
        designate_host                       => $designate_host,
        designate_host_standby               => $designate_host_standby,
        second_region_designate_host         => $second_region_designate_host,
        second_region_designate_host_standby => $second_region_designate_host_standby,
        labweb_hosts                         => $labweb_hosts,
        require                              => Class['profile::openstack::base::keystone::db'],
    }
    contain '::profile::openstack::base::keystone::service'

    class {'::profile::openstack::base::keystone::hooks':
        version => $version,
    }
    contain '::profile::openstack::base::keystone::hooks'

    class {'::openstack::keystone::monitor::services':
        active      => $::fqdn == $keystone_host,
        auth_port   => $auth_port,
        public_port => $public_port,
    }
    contain '::openstack::keystone::monitor::services'
}
