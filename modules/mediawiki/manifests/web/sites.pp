class mediawiki::web::sites (
    $domain_suffix = 'org',
    $portal_dir = 'portal'
) {
    tag 'mediawiki', 'mw-apache-config'

    #common code snippets that are included in the virtualhosts.
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

    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }

    if $::realm == 'labs' {
        # w-beta.wmflabs.org depends on proxy_http
        include ::apache::mod::proxy_http
        apache::site { 'beta-specific':
            source   => 'puppet:///modules/mediawiki/apache/beta/sites/beta_specific.conf',
            priority => 1,
        }
    }

    $rewrite_portal = $portal_dir != 'portal'
    apache::site { 'wwwportals':
        content  => template('mediawiki/apache/sites/wwwportals.conf.erb'),
        priority => 1,
    }

    apache::site { 'redirects':
        source  => 'puppet:///mediawiki/apache/sites/redirects.conf',
        priority => 2,
    }

    apache::site { 'main':
        content   => template('mediawiki/apache/sites/main.conf.erb'),
        priority => 3,
    }

    apache::site { 'remnant':
        content   => template('mediawiki/apache/sites/remnant.conf.erb'),
        priority => 4,
    }

    apache::site { 'search.wikimedia':
        source   => 'puppet:///mediawiki/apache/sites/search.wikimedia.conf',
        priority => 5,
    }

    apache::site { 'secure.wikimedia':
        source   => 'puppet:///mediawiki/apache/sites/secure.wikimedia.conf',
        priority => 6,
    }

    apache::site { 'wikimania':
        content   => template('mediawiki/apache/sites/wikimania.conf.erb'),
        priority => 7,
    }

    apache::site { 'wikimedia':
        content   => template('mediawiki/apache/sites/wikimedia.conf.erb'),
        priority => 8,
    }

    apache::site { 'foundation':
        source   => 'puppet:///mediawiki/apache/sites/foundation.conf',
        priority => 9,
    }
}
