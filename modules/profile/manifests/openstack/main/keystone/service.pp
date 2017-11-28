class profile::openstack::main::keystone::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $osm_host = hiera('profile::openstack::main::osm_host'),
    $db_host = hiera('profile::openstack::main::keystone::db_host'),
    $token_driver = hiera('profile::openstack::main::keystone::token_driver'),
    $db_pass = hiera('profile::openstack::main::keystone::db_pass'),
    $db_name = hiera(profile::openstack::base::keystone::db_name),
    $db_user = hiera(profile::openstack::base::keystone::db_user),
    $nova_db_pass = hiera('profile::openstack::main::nova::db_pass'),
    $ldap_hosts = hiera('profile::openstack::main::ldap_hosts'),
    $ldap_user_pass = hiera('profile::openstack::main::ldap_user_pass'),
    $wiki_status_consumer_token = hiera('profile::openstack::main::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = hiera('profile::openstack::main::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = hiera('profile::openstack::main::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = hiera('profile::openstack::main::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = hiera('profile::openstack::main::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = hiera('profile::openstack::main::keystone::wiki_consumer_secret'),
    $wiki_access_token = hiera('profile::openstack::main::keystone::wiki_access_token'),
    $wiki_access_secret = hiera('profile::openstack::main::keystone::wiki_access_secret'),
    $wmflabsdotorg_admin = hiera('profile::openstack::main::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::main::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::main::designate::wmflabsdotorg_project'),
    $spread_check_user = hiera('profile::openstack::main::monitor::spread_check_user'),
    $spread_check_password = hiera('profile::openstack::main::monitor::spread_check_password'),
    $labs_hosts_range = hiera('profile::openstack::main::labs_hosts_range'),
    $nova_controller_standby = hiera('profile::openstack::main::nova_controller_standby'),
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $designate_host_standby = hiera('profile::openstack::main::designate_host_standby'),
    $horizon_host = hiera('profile::openstack::main::horizon_host'),
    ) {

    require ::profile::openstack::main::clientlib
    class {'::profile::openstack::base::keystone::service':
        version                     => $version,
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
        horizon_host                => $horizon_host,
    }

    class {'::profile::openstack::base::keystone::hooks':
        version => $version,
    }

    class {'::openstack::keystone::cleanup':
        active  => $::fqdn == $nova_controller,
        db_user => $db_user,
        db_pass => $db_pass,
        db_host => $db_host,
        db_name => $db_name,
    }

    class {'::openstack::monitor::spreadcheck':
        active          => $::fqdn == $nova_controller,
        nova_controller => $nova_controller,
        nova_user       => $spread_check_user,
        nova_password   => $spread_check_password,
    }
}
