class profile::openstack::base::keystone::service(
    $version = hiera('profile::openstack::base::version'),
    $region = hiera('profile::openstack::base::region'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $osm_host = hiera('profile::openstack::base::osm_host'),
    $db_name = hiera('profile::openstack::base::keystone::db_name'),
    $db_user = hiera('profile::openstack::base::keystone::db_user'),
    $db_pass = hiera('profile::openstack::base::keystone::db_pass'),
    $db_host = hiera('profile::openstack::base::keystone::db_host'),
    $nova_db_pass = hiera('profile::openstack::base::nova::db_pass'),
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
    $wmflabsdotorg_admin = hiera('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::base::designate::wmflabsdotorg_project'),
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    $nova_controller_standby = hiera('profile::openstack::base::nova_controller_standby'),
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $designate_host_standby = hiera('profile::openstack::base::designate_host_standby'),
    $horizon_host = hiera('profile::openstack::base::horizon_host'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    ) {

    include ::network::constants
    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    class {'::openstack::keystone::service':
        active                      => ($::fqdn == $nova_controller),
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
    contain '::openstack::keystone::service'

    class {'::openstack::keystone::monitor':
        active      => $::fqdn == $nova_controller,
        auth_port   => $auth_port,
        public_port => $public_port,
    }
    contain '::openstack::keystone::monitor'

    class {'::openstack::util::envscripts':
        ldap_user_pass        => $ldap_user_pass,
        nova_controller       => $nova_controller,
        region                => $region,
        nova_db_pass          => $nova_db_pass,
        wmflabsdotorg_admin   => $wmflabsdotorg_admin,
        wmflabsdotorg_pass    => $wmflabsdotorg_pass,
        wmflabsdotorg_project => $wmflabsdotorg_project,
    }
    contain '::openstack::util::envscripts'

    class {'::openstack::util::admin_scripts':
        version => $version,
    }
    contain '::openstack::util::admin_scripts'

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")

    # keystone admin API only for openstack services that might need it
    ferm::rule{'keystone_admin':
        ensure => 'present',
        rule   => "saddr (${labs_hosts_range} @resolve(${nova_controller_standby}) @resolve(${nova_api_host})
                             @resolve(${designate_host}) @resolve(${designate_host_standby}) @resolve(${horizon_host})
                             ${labweb_ips}
                             @resolve(${osm_host})
                             ) proto tcp dport (35357) ACCEPT;",
    }

    ferm::rule{'keystone_public':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (5000) ACCEPT;",
    }
}
