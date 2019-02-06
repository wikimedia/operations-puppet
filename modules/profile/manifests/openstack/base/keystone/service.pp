class profile::openstack::base::keystone::service(
    $daemon_active = hiera('profile::openstack::base::keystone::daemon_active'),
    $version = hiera('profile::openstack::base::version'),
    $region = hiera('profile::openstack::base::region'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $osm_host = hiera('profile::openstack::base::osm_host'),
    $db_name = hiera('profile::openstack::base::keystone::db_name'),
    $db_user = hiera('profile::openstack::base::keystone::db_user'),
    $db_pass = hiera('profile::openstack::base::keystone::db_pass'),
    $db_host = hiera('profile::openstack::base::keystone::db_host'),
    $db_max_pool_size = hiera('profile::openstack::base::keystone::db_max_pool_size'),
    $admin_workers = hiera('profile::openstack::base::keystone::admin_workers'),
    $public_workers = hiera('profile::openstack::base::keystone::public_workers'),
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
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::base::labs_hosts_range_v6'),
    $nova_controller_standby = hiera('profile::openstack::base::nova_controller_standby'),
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $designate_host_standby = hiera('profile::openstack::base::designate_host_standby'),
    $second_region_designate_host = hiera('profile::openstack::base::second_region_designate_host'),
    $second_region_designate_host_standby = hiera('profile::openstack::base::second_region_designate_host_standby'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    ) {

    include ::network::constants
    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    if ($daemon_active) {
        # support for a 2 controller nodes deployment
        $active = ($::fqdn == $keystone_host)
    } else {
        $active = false
    }

    class {'::openstack::keystone::service':
        active                      => $active,
        version                     => $version,
        keystone_host               => $keystone_host,
        osm_host                    => $osm_host,
        db_name                     => $db_name,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_host                     => $db_host,
        db_max_pool_size            => $db_max_pool_size,
        admin_workers               => $admin_workers,
        public_workers              => $public_workers,
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

    class {'::openstack::util::admin_scripts':
        version => $version,
    }
    contain '::openstack::util::admin_scripts'

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_ip6s = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")

    # keystone admin API only for openstack services that might need it
    ferm::rule{'keystone_admin':
        ensure => 'present',
        rule   => "saddr (${labs_hosts_range} ${labs_hosts_range_v6}
                             @resolve(${nova_controller_standby}) @resolve(${nova_controller_standby}, AAAA) @resolve(${nova_api_host})
                             @resolve(${designate_host}) @resolve(${designate_host_standby})
                             @resolve(${designate_host}, AAAA) @resolve(${designate_host_standby}, AAAA)
                             @resolve(${second_region_designate_host}) @resolve(${second_region_designate_host}, AAAA)
                             @resolve(${second_region_designate_host_standby}) @resolve(${second_region_designate_host_standby}, AAAA)
                             ${labweb_ips} ${labweb_ip6s}
                             @resolve(${osm_host})
                             ) proto tcp dport (35357) ACCEPT;",
    }

    ferm::rule{'keystone_public':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (5000) ACCEPT;",
    }
}
