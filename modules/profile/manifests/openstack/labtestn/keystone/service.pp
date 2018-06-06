class profile::openstack::labtestn::keystone::service(
    $version = hiera('profile::openstack::labtestn::version'),
    $region = hiera('profile::openstack::labtestn::region'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $glance_host = hiera('profile::openstack::labtest::nova_controller'),
    $osm_host = hiera('profile::openstack::labtestn::osm_host'),
    $db_host = hiera('profile::openstack::labtest::keystone::db_host'),
    $token_driver = hiera('profile::openstack::labtestn::keystone::token_driver'),
    $db_pass = hiera('profile::openstack::labtest::keystone::db_pass'),
    $nova_db_pass = hiera('profile::openstack::labtest::nova::db_pass'),
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
    $wmflabsdotorg_admin = hiera('profile::openstack::labtestn::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::labtestn::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::labtestn::designate::wmflabsdotorg_project'),
    $labs_hosts_range = hiera('profile::openstack::labtestn::labs_hosts_range'),
    $nova_controller_standby = hiera('profile::openstack::labtestn::nova_controller_standby'),
    $nova_api_host = hiera('profile::openstack::labtestn::nova_api_host'),
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    $designate_host_standby = hiera('profile::openstack::labtest::designate_host_standby'),
    $labweb_hosts = hiera('profile::openstack::labtestn::labweb_hosts'),
    $puppetmaster_hostname = hiera('profile::openstack::labtestn::puppetmaster_hostname'),
    $auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $public_port = hiera('profile::openstack::base::keystone::public_port'),
    ) {

    class{'::profile::openstack::base::keystone::db':
        labs_hosts_range      => $labs_hosts_range,
        puppetmaster_hostname => $puppetmaster_hostname,
        designate_host        => $designate_host,
        osm_host              => $osm_host,
    }
    contain '::profile::openstack::base::keystone::db'

    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::keystone::service':
        version                     => $version,
        region                      => $region,
        nova_controller             => $nova_controller,
        osm_host                    => $osm_host,
        db_host                     => $db_host,
        token_driver                => $token_driver,
        db_pass                     => $db_pass,
        nova_db_pass                => $nova_db_pass,
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
        wmflabsdotorg_admin         => $wmflabsdotorg_admin,
        wmflabsdotorg_pass          => $wmflabsdotorg_pass,
        wmflabsdotorg_project       => $wmflabsdotorg_project,
        labs_hosts_range            => $labs_hosts_range,
        nova_controller_standby     => $nova_controller_standby,
        nova_api_host               => $nova_api_host,
        designate_host              => $designate_host,
        designate_host_standby      => $designate_host_standby,
        labweb_hosts                => $labweb_hosts,
        require                     => Class['profile::openstack::base::keystone::db'],
    }
    contain '::profile::openstack::base::keystone::service'

    class {'::profile::openstack::base::keystone::hooks':
        version => $version,
    }
    contain '::profile::openstack::base::keystone::hooks'

    class {'::openstack::keystone::monitor::services':
        active      => $::fqdn == $nova_controller,
        auth_port   => $auth_port,
        public_port => $public_port,
    }
    contain '::openstack::keystone::monitor::services'

    # allow foreign glance to call back to admin auth port
    # to validate issued tokens
    ferm::rule{'labtest_glance_35357':
        ensure => 'present',
        rule   => "saddr @resolve(${glance_host}) proto tcp dport (35357) ACCEPT;",
    }

    # allow foreign designate(and co) to call back to admin auth port
    # to validate issued tokens
    ferm::rule{'labtest_designate_35357':
        ensure => 'present',
        rule   => "saddr @resolve(${designate_host}) proto tcp dport (35357) ACCEPT;",
    }
}
