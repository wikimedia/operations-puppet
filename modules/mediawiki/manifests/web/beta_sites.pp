class mediawiki::web::beta_sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::mod_conf { 'php5':
        ensure => 'absent',
    }

    # Now the sites, in strict sequence
    include ::mediawiki::web::sites

    apache::site { 'www.wikipedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/www.wikipedia.conf',
        priority => 1,
    }

    apache::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/main.conf',
        priority => 2,
    }

    apache::site { 'wikidata':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikidata.conf',
        priority => 4,
    }

    apache::site { 'wikisource':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikisource.conf',
        priority => 5,
    }

    apache::site { 'wikispecies':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikispecies.conf',
        priority => 6,
    }

    apache::site { 'wikiversity':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikiversity.conf',
        priority => 7,
    }

    apache::site { 'wikiquote':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikiquote.conf',
        priority => 8,
    }

    apache::site { 'testwiki':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/testwiki.conf',
        priority => 9,
    }

    apache::site { 'wiktionary':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wiktionary.conf',
        priority => 10,
    }

    apache::site { 'wikinews':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikinews.conf',
        priority => 11,
    }

    apache::site { 'loginwiki':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/loginwiki.conf',
        priority => 12,
    }

    apache::site { 'upload':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/upload.conf',
        priority => 13,
    }

    apache::site { 'config':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/config.conf',
        priority => 14,
    }

    apache::site { 'wmflabs':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wmflabs.conf',
        priority => 15,
    }

    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikimedia.conf',
        priority => 16,
    }

    apache::site { 'remnant':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/remnant.conf',
        priority => 20,
    }

    apache::conf { 'logging':
        source   => 'puppet:///modules/mediawiki/apache/beta/logging.conf',
        priority => 20,
    }

}
