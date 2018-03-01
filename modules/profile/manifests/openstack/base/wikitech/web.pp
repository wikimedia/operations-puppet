class profile::openstack::base::wikitech::web(
    $osm_host = hiera('profile::openstack::base::wikitech::web::osm_host'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $webserver_hostname_aliases = hiera('profile::openstack::base::wikitech::webserver_hostname_aliases'),
    $wikidb = hiera('profile::openstack::base::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = hiera('profile::openstack::base::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    ) {

    class {'::mediawiki': }
    class {'::mediawiki::multimedia':}
    class {'::profile::backup::host':}
    class {'hhvm::admin':}


    # common code snippets that are included in the virtualhosts.
    # from ::mediawiki::web::sites
    file { '/etc/apache2/sites-enabled/wikimedia-common.incl':
        ensure  => present,
        content => template('mediawiki/apache/sites/wikimedia-common.incl.erb'),
        before  => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/wikimedia-legacy.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikimedia-legacy.incl',
        before => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/public-wiki-rewrites.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/public-wiki-rewrites.incl',
        before => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/api-rewrites.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/api-rewrites.incl',
        before => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/wikidata-uris.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikidata-uris.incl',
        before => Service['apache2'],
    }

    # For Math extensions file (T126628)
    file { '/srv/math-images':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    class { '::openstack::wikitech::web':
        webserver_hostname                 => $osm_host,
        webserver_hostname_aliases         => $webserver_hostname_aliases,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    ferm::service { 'wikitech_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }
}
