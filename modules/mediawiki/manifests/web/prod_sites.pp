class mediawiki::web::prod_sites {
    tag 'mediawiki', 'mw-apache-config'

    #common code snippets that are included in the virtualhosts.
    file { '/etc/apache2/sites-enabled/wikimedia-common.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikimedia-common.incl',
        notify => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/wikimedia-legacy.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikimedia-legacy.incl',
        notify => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/public-wiki-rewrites.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/public-wiki-rewrites.incl',
        notify => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/api-rewrites.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/api-rewrites.incl',
        notify => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/wikidata-uris.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikidata-uris.incl',
        notify => Service['apache2'],
    }

    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }

    apache::site { 'wwwportals':
        source   => 'puppet:///modules/mediawiki/apache/sites/wwwportals.conf',
        priority => 1,
    }

    apache::site { 'redirects':
        source   => 'puppet:///modules/mediawiki/apache/sites/redirects.conf',
        priority => 2,
    }

    apache::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/sites/main.conf',
        priority => 3,
    }

    apache::site { 'remnant':
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf',
        priority => 4,
    }

    apache::site { 'search.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf',
        priority => 5,
    }

    apache::site { 'secure.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf',
        priority => 6,
    }

    apache::site { 'wikimania':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf',
        priority => 7,
    }

    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf',
        priority => 8,
    }

    apache::site { 'foundation':
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf',
        priority => 9,
    }
}
