class profile::openstack::eqiad1::keystone::service(
    $daemon_active = hiera('profile::openstack::eqiad1::keystone::daemon_active'),
    $version = hiera('profile::openstack::eqiad1::version'),
    $region = hiera('profile::openstack::eqiad1::region'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $osm_host = hiera('profile::openstack::eqiad1::osm_host'),
    $db_host = hiera('profile::openstack::eqiad1::keystone::db_host'),
    $token_driver = hiera('profile::openstack::eqiad1::keystone::token_driver'),
    $db_pass = hiera('profile::openstack::eqiad1::keystone::db_pass'),
    $nova_db_pass = hiera('profile::openstack::eqiad1::nova::db_pass'),
    $ldap_hosts = hiera('profile::openstack::eqiad1::ldap_hosts'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $wiki_status_consumer_token = hiera('profile::openstack::eqiad1::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = hiera('profile::openstack::eqiad1::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = hiera('profile::openstack::eqiad1::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = hiera('profile::openstack::eqiad1::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = hiera('profile::openstack::eqiad1::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = hiera('profile::openstack::eqiad1::keystone::wiki_consumer_secret'),
    $wiki_access_token = hiera('profile::openstack::eqiad1::keystone::wiki_access_token'),
    $wiki_access_secret = hiera('profile::openstack::eqiad1::keystone::wiki_access_secret'),
    $wmflabsdotorg_admin = hiera('profile::openstack::eqiad1::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::eqiad1::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::eqiad1::designate::wmflabsdotorg_project'),
    $labs_hosts_range = hiera('profile::openstack::eqiad1::labs_hosts_range'),
    $nova_controller_standby = hiera('profile::openstack::eqiad1::nova_controller_standby'),
    $nova_api_host = hiera('profile::openstack::eqiad1::nova_api_host'),
    $designate_host = hiera('profile::openstack::eqiad1::designate_host'),
    $designate_host_standby = hiera('profile::openstack::eqiad1::designate_host_standby'),
    $labweb_hosts = hiera('profile::openstack::eqiad1::labweb_hosts'),
    $puppetmaster_hostname = hiera('profile::openstack::eqiad1::puppetmaster_hostname'),
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

    require ::profile::openstack::eqiad1::clientlib
    class {'::profile::openstack::base::keystone::service':
        daemon_active               => $daemon_active,
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

    file { '/etc/cron.hourly/keystone':
        ensure => absent,
    }
}
