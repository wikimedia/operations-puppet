class mediawiki::web::beta_sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::mod_conf { 'php5':
        ensure => 'absent',
    }

    # w-beta.wmflabs.org depends on proxy_http
    include ::apache::mod::proxy_http
    apache::site { 'beta-specific':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/beta_specific.conf',
        priority => 1,
    }

    apache::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/main.conf',
        priority => 1,
    }

    apache::site { 'wikibooks':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikibooks.conf',
        priority => 2,
    }

    apache::site { 'wikipedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikipedia.conf',
        priority => 3,
    }

    apache::site { 'wikidata':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikidata.conf',
        priority => 4,
    }

    apache::site { 'wikisource':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikisource.conf',
        priority => 5,
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
        ensure   => absent,
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

    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikimedia.conf',
        priority => 16,
    }

    apache::site { 'wikivoyage':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikivoyage.conf',
        priority => 17,
    }

}
