class profile::openstack::base::wikitech::web(
    $osm_host = hiera('profile::openstack::base::wikitech::web::osm_host'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $webserver_hostname_aliases = hiera('profile::openstack::base::wikitech::webserver_hostname_aliases'),
    $wikidb = hiera('profile::openstack::base::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = hiera('profile::openstack::base::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    ) {

    include ::mediawiki
    include ::scap::scripts
    require ::mediawiki::users
    include ::mediawiki::multimedia
    include ::mediawiki::scap
    include ::profile::backup::host
    include ::nrpe
    include ::imagemagick::install

    include ::mediawiki::packages::tex

    class { '::openstack::wikitech::web':
        webserver_hostname                 => $osm_host,
        webserver_hostname_aliases         => $webserver_hostname_aliases,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    include ::mediawiki::packages::math
    # For Math extensions file (T126628)
    file { '/srv/math-images':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    ferm::service { 'wikitech_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    ferm::service { 'deployment-ssh':
        proto  => 'tcp',
        port   => '22',
        srange => '$DEPLOYMENT_HOSTS',
    }
}
