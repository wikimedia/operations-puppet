class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'
    # Now the sites, in strict sequence
    apache2::site { 'nonexistent':
        ensure   => present,
        priority => '00',
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf'
    }

    apache2::site { 'wwwportals':
        ensure   => present,
        priority => '01',
        source   => 'puppet:///modules/mediawiki/apache/sites/wwwportals.conf'
    }

    apache2::site { 'redirects':
        # this must be generated with the redirects.dat file still in apache-config,
        # then committed to puppet. This will change soon.
        ensure   => present,
        priority => '02',
        source   => 'puppet:///modules/mediawiki/apache/sites/redirects.conf'
    }

    apache2::site { 'main':
        ensure   => present,
        priority => '03',
        source   => 'puppet:///modules/mediawiki/apache/sites/main.conf'
    }

    apache2::site { 'remnant':
        ensure   => present,
        priority => '04',
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf'
    }

    apache2::site { 'search.wikimedia':
        ensure   => present,
        priority => '05',
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf'
    }

    apache2::site { 'secure.wikimedia':
        ensure   => present,
        priority => '06',
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf'
    }

    apache2::site { 'wikimania':
        ensure   => present,
        priority => '07',
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf'
    }

    apache2::site { 'wikimedia':
        ensure   => present,
        priority => '08',
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf'
    }

    apache2::site { 'foundation':
        ensure   => present,
        priority => '09',
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf'
    }
}
