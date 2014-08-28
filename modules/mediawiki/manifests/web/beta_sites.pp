class mediawiki::web::beta_sites {
    tag 'mediawiki', 'mw-apache-config'
    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/nonexistent.conf',
        priority => 0,
    }

    apache::site { 'www.wikipedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/www.wikipedia.conf',
        priority => 1,
    }

    apache::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/main.conf',
        priority => 3,
    }

    apache::site { 'remnant':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/remnant.conf',
        priority => 4,
    }

    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikimedia.conf',
        priority => 5,
    }
}
