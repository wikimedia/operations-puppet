class mediawiki::web::sites (
    String $domain_suffix = 'org',
) {
    tag 'mediawiki', 'mw-apache-config'

    #common code snippets that were included in the virtualhosts. They now need to be removed from disk
    file { ['/etc/apache2/sites-enabled/wikimedia-common.incl', '/etc/apache2/sites-enabled/wikimedia-legacy.incl',
            '/etc/apache2/sites-enabled/api-rewrites.incl', '/etc/apache2/sites-enabled/public-wiki-rewrites.incl']:
        ensure  => absent,
    }

    file { '/etc/apache2/sites-enabled/wikidata-uris.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikidata-uris.incl',
        before => Service['apache2'],
    }

    ::httpd::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }

    ::httpd::site { 'wwwportals':
        content  => template('mediawiki/apache/sites/wwwportals.conf.erb'),
        priority => 1,
    }
}
