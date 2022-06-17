class profile::openstack::base::trove(
    String              $version                 = lookup('profile::openstack::base::version'),
    Integer             $workers                 = lookup('profile::openstack::base::trove::workers'),
    Array[Stdlib::Fqdn] $openstack_controllers   = lookup('profile::openstack::base::openstack_controllers'),
    String              $db_user                 = lookup('profile::openstack::base::trove::db_user'),
    String              $db_pass                 = lookup('profile::openstack::base::trove::db_pass'),
    String              $db_name                 = lookup('profile::openstack::base::trove::db_name'),
    Stdlib::Fqdn        $db_host                 = lookup('profile::openstack::base::trove::db_host'),
    String              $ldap_user_pass          = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn        $keystone_fqdn           = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port        $auth_port               = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port        $internal_auth_port      = lookup('profile::openstack::base::keystone::internal_port'),
    String              $region                  = lookup('profile::openstack::base::region'),
    Stdlib::Port        $api_bind_port           = lookup('profile::openstack::base::trove::api_bind_port'),
    String              $rabbit_user             = lookup('profile::openstack::base::nova::rabbit_user'),
    String              $rabbit_pass             = lookup('profile::openstack::base::nova::rabbit_pass'),
    String              $trove_guest_rabbit_user = lookup('profile::openstack::base::trove::trove_guest_rabbit_user'),
    String              $trove_guest_rabbit_pass = lookup('profile::openstack::base::trove::trove_guest_rabbit_pass'),
    String              $trove_service_user_pass = lookup('profile::openstack::base::trove::trove_user_pass'),
    String              $trove_quay_user         = lookup('profile::openstack::base::trove::quay_user'),
    String              $trove_quay_pass         = lookup('profile::openstack::base::trove::quay_pass'),
    String              $trove_dns_zone          = lookup('profile::openstack::base::trove::dns_zone'),
    String              $trove_dns_zone_id       = lookup('profile::openstack::base::trove::dns_zone_id'),
    ) {

    $keystone_admin_uri = "https://${keystone_fqdn}:${auth_port}"
    $keystone_internal_uri = "https://${keystone_fqdn}:${internal_auth_port}"
    $designate_internal_uri = "https://${keystone_fqdn}:29001"

    class { '::openstack::trove::service':
        version                 => $version,
        workers                 => $workers,
        openstack_controllers   => $openstack_controllers,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        keystone_admin_uri      => $keystone_admin_uri,
        keystone_internal_uri   => $keystone_internal_uri,
        designate_internal_uri  => $designate_internal_uri,
        region                  => $region,
        api_bind_port           => $api_bind_port,
        rabbit_user             => $rabbit_user,
        rabbit_pass             => $rabbit_pass,
        trove_guest_rabbit_user => $trove_guest_rabbit_user,
        trove_guest_rabbit_pass => $trove_guest_rabbit_pass,
        trove_service_user_pass => $trove_service_user_pass,
        trove_quay_user         => $trove_quay_user,
        trove_quay_pass         => $trove_quay_pass,
        trove_dns_zone          => $trove_dns_zone,
        trove_dns_zone_id       => $trove_dns_zone_id,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'trove_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (8779 28779) ACCEPT;",
    }

    openstack::db::project_grants { 'trove':
        access_hosts => $openstack_controllers,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
