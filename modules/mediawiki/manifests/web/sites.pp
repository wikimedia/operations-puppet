class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'
    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        ensure   => present,
        priority => 0,
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf'
    }

    apache::site { 'wwwportals':
        ensure   => present,
        priority => 1,
        source   => 'puppet:///modules/mediawiki/apache/sites/wwwportals.conf'
    }

    apache::site { 'redirects':
        # this must be generated with the redirects.dat file still in apache-config,
        # then committed to puppet. This will change soon.
        ensure   => present,
        priority => 2,
        source   => 'puppet:///modules/mediawiki/apache/sites/redirects.conf'
    }

    apache::site { 'main':
        ensure   => present,
        priority => 3,
        source   => 'puppet:///modules/mediawiki/apache/sites/main.conf'
    }

    apache::site { 'remnant':
        ensure   => present,
        priority => 4,
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf'
    }

    apache::site { 'search.wikimedia':
        ensure   => present,
        priority => 5,
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf'
    }

    apache::site { 'secure.wikimedia':
        ensure   => present,
        priority => 6,
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf'
    }

    apache::site { 'wikimania':
        ensure   => present,
        priority => 7,
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf'
    }

    apache::site { 'wikimedia':
        ensure   => present,
        priority => 8,
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf'
    }

    apache::site { 'foundation':
        ensure   => present,
        priority => 9,
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf'
    }
}
