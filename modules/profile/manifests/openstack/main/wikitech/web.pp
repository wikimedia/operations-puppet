class profile::openstack::main::wikitech::web(
    $osm_host = hiera('profile::openstack::main::wikitech::web::osm_host'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $webserver_hostname_aliases = hiera('profile::openstack::main::wikitech::webserver_hostname_aliases'),
    $wikidb = hiera('profile::openstack::main::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = hiera('profile::openstack::base::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = hiera('profile::openstack::main::ldap_user_pass'),
    $wikitech_static_sync_host = hiera('profile::openstack::main::wikitech::wikitech_static_sync_host'),
    ) {

    class {'profile::openstack::base::wikitech::web':
        osm_host                           => $osm_host,
        nova_controller                    => $nova_controller,
        webserver_hostname_aliases         => $webserver_hostname_aliases,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    if $wikitech_static_sync_host == $::hostname {
        class {'::openstack::wikitech::wikitech_static_sync': }
    }
}
