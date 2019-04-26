class profile::openstack::labtest::wikitech::web(
    $osm_host = hiera('profile::openstack::labtest::wikitech::web::osm_host'),
    $webserver_hostname_aliases = hiera('profile::openstack::labtest::wikitech::webserver_hostname_aliases'),
    $wikidb = hiera('profile::openstack::labtest::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = hiera('profile::openstack::labtest::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    ) {

    class {'profile::openstack::base::wikitech::web':
        osm_host                           => $osm_host,
        webserver_hostname_aliases         => $webserver_hostname_aliases,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
        phabricator_api_token              => '',
        gerrit_api_user                    => '',
        gerrit_api_password                => '',
    }
}
