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

    class { '::scap::scripts': }

    # The following is derived from hhvm::admin
    #  but reworked to avoid package conflicts
    include ::network::constants
    httpd::conf { 'hhvm_admin_port':
        content  => "Listen 9002\n",
        priority => 1,
    }

    httpd::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }

    # Add headers lost by mod_proxy_fastcgi
    httpd::conf { 'fcgi_headers':
        source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
        priority => 0,
    }

    httpd::site { 'hhvm_admin':
        content => template('hhvm/hhvm-admin.conf.erb'),
    }

    ferm::service { 'hhvm_admin':
        proto  => 'tcp',
        port   => 9002,
        srange => '$DOMAIN_NETWORKS',
    }
    # end hhvm::admin bits

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
