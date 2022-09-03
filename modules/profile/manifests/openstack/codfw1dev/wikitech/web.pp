class profile::openstack::codfw1dev::wikitech::web(
    $osm_host = lookup('profile::openstack::codfw1dev::wikitech::web::osm_host'),
    $wikidb = lookup('profile::openstack::codfw1dev::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = lookup('profile::openstack::codfw1dev::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    ) {

    class {'profile::openstack::base::wikitech::web':
        osm_host                           => $osm_host,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    class {'::openstack::wikitech::wikitech_static_sync': }
}
