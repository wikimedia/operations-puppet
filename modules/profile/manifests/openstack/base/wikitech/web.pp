class profile::openstack::base::wikitech::web(
    $osm_host = lookup('profile::openstack::base::wikitech::web::osm_host'),
    $wikidb = lookup('profile::openstack::base::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = lookup('profile::openstack::base::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    $phabricator_api_token = lookup('profile::openstack::base::wikitech::web::phabricator_api_token'),
    $gerrit_api_user = lookup('profile::openstack::base::wikitech::web::gerrit_api_user'),
    $gerrit_api_password = lookup('profile::openstack::base::wikitech::web::gerrit_api_password'),
    Boolean $install_fonts = lookup('profile::openstack::base::wikitech::web::install_fonts', {'default_value' => false}),
) {

    require profile::mediawiki::common
    require ::profile::services_proxy::envoy

    # we may not need fonts anymore! (T294378)
    $font_ensure = $install_fonts.bool2str('installed','absent')
    class { '::mediawiki::packages::fonts':
        ensure => $font_ensure,
    }

    class {'::profile::backup::host':}

    class { '::scap::scripts': }

    # Wikitech needs to talk to LDAP directories
    php::extension { 'ldap':
        versioned_packages => true,
    }

    # Packages (potentially) used for local image scaling, this can be removed once
    # Thumbor has been setup for labweb:
    package { [
        'fontconfig-config',
        'libimage-exiftool-perl',
        'libjpeg-turbo-progs',
        'netpbm',
    ]:
        ensure => present,
    }

    httpd::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }

    # Add headers lost by mod_proxy_fastcgi
    httpd::conf { 'fcgi_headers':
        source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
        priority => 0,
    }

    # Remove old common snippets
    file { '/etc/apache2/sites-enabled/wikimedia-common.incl':
        ensure  => absent,
    }

    file { '/etc/apache2/sites-enabled/wikimedia-legacy.incl':
        ensure => absent,
    }

    file { '/etc/apache2/sites-enabled/public-wiki-rewrites.incl':
        ensure => absent
    }

    file { '/etc/apache2/sites-enabled/api-rewrites.incl':
        ensure => absent,
    }

    file { '/etc/apache2/sites-enabled/wikidata-uris.incl':
        ensure => absent,
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
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
        phabricator_api_token              => $phabricator_api_token,
        gerrit_api_user                    => $gerrit_api_user,
        gerrit_api_password                => $gerrit_api_password,
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }
}
