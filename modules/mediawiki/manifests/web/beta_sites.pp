class mediawiki::web::beta_sites {
    tag 'mediawiki', 'mw-apache-config'
    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/nonexistent.conf',
        priority => 0,
    }

    apache::site { 'www.wikipedia':
        content   => template('mediawiki/apache/beta/sites/www.wikipedia.conf.erb'),
        priority => 1,
    }

    apache::site { 'main':
        content   => template('mediawiki/apache/beta/sites/main.conf.erb'),
        priority => 2,
    }

    apache::site { 'wikidata':
        content   => template('mediawiki/apache/beta/sites/wikidata.conf.erb'),
        priority => 4,
    }

    apache::site { 'wikisource':
        content   => template('mediawiki/apache/beta/sites/wikisource.conf.erb'),
        priority => 5,
    }

    apache::site { 'wikispecies':
        content   => template('mediawiki/apache/beta/sites/wikispecies.conf.erb'),
        priority => 6,
    }

    apache::site { 'wikiversity':
        content   => template('mediawiki/apache/beta/sites/wikiversity.conf.erb'),
        priority => 7,
    }

    apache::site { 'wikiquote':
        content   => template('mediawiki/apache/beta/sites/wikiquote.conf.erb'),
        priority => 8,
    }

    apache::site { 'testwiki':
        content   => template('mediawiki/apache/beta/sites/testwiki.conf.erb'),
        priority => 9,
    }

    apache::site { 'wiktionary':
        content   => template('mediawiki/apache/beta/sites/wiktionary.conf.erb'),
        priority => 10,
    }

    apache::site { 'wikinews':
        content   => template('mediawiki/apache/beta/sites/wikinews.conf.erb'),
        priority => 11,
    }

    apache::site { 'loginwiki':
        content   => template('mediawiki/apache/beta/sites/loginwiki.conf.erb'),
        priority => 12,
    }

    apache::site { 'upload':
        content   => template('mediawiki/apache/beta/sites/upload.conf.erb'),
        priority => 13,
    }

    apache::site { 'config':
        content   => template('mediawiki/apache/beta/sites/config.conf.erb'),
        priority => 14,
    }

    apache::site { 'wmflabs':
        content   => template('mediawiki/apache/beta/sites/wmflabs.conf.erb'),
        priority => 15,
    }

    apache::site { 'wikimedia':
        content   => template('mediawiki/apache/beta/sites/wikimedia.conf.erb'),
        priority => 16,
    }

    apache::site { 'remnant':
        content   => template('mediawiki/apache/beta/sites/remnant.conf.erb'),
        priority => 20,
    }

    apache::conf { 'logging':
        source   => 'puppet:///modules/mediawiki/apache/beta/logging.conf'),
        priority => 20,
    }

}
