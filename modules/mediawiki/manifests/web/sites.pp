class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'
    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        ensure   => present,
        priority => '00',
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf'
    }

    apache::site { 'wwwportals':
        ensure   => present,
        priority => '01',
        source   => 'puppet:///modules/mediawiki/apache/sites/wwwportals.conf'
    }

    apache::site { 'redirects':
        # this must be generated with the redirects.dat file still in apache-config,
        # then committed to puppet. This will change soon.
        ensure   => present,
        priority => '02',
        source   => 'puppet:///modules/mediawiki/apache/sites/redirects.conf'
    }

    apache::site { 'main':
        ensure   => present,
        priority => '03',
        source   => 'puppet:///modules/mediawiki/apache/sites/main.conf'
    }

    apache::site { 'remnant':
        ensure   => present,
        priority => '04',
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf'
    }

    apache::site { 'search.wikimedia':
        ensure   => present,
        priority => '05',
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf'
    }

    apache::site { 'secure.wikimedia':
        ensure   => present,
        priority => '06',
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf'
    }

    apache::site { 'wikimania':
        ensure   => present,
        priority => '07',
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf'
    }

    apache::site { 'wikimedia':
        ensure   => present,
        priority => '08',
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf'
    }

    apache::site { 'foundation':
        ensure   => present,
        priority => '09',
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf'
    }
}
