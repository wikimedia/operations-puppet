class mediawiki::web::prod_sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::site { 'redirects':
        content  => compile_redirects('puppet:///modules/mediawiki/apache/sites/redirects/redirects.dat'),
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
