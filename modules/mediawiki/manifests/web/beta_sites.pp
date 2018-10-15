class mediawiki::web::beta_sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::mod_conf { 'php5':
        ensure => 'absent',
    }

    # w-beta.wmflabs.org depends on proxy_http
    include ::apache::mod::proxy_http
    ::httpd::site { 'beta-specific':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/beta_specific.conf',
        priority => 1,
    }

    ::httpd::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/main.conf',
        priority => 1,
    }

    ::httpd::site { 'wikibooks':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikibooks.conf',
        priority => 2,
    }

    ::httpd::site { 'wikipedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikipedia.conf',
        priority => 3,
    }

    ::httpd::site { 'wikidata':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikidata.conf',
        priority => 4,
    }

    ::httpd::site { 'wikisource':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikisource.conf',
        priority => 5,
    }

    ::httpd::site { 'wikiversity':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikiversity.conf',
        priority => 7,
    }

    ::httpd::site { 'wikiquote':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikiquote.conf',
        priority => 8,
    }

    ::httpd::site { 'testwiki':
        ensure   => absent,
        priority => 9,
    }

    ::httpd::site { 'wiktionary':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wiktionary.conf',
        priority => 10,
    }

    ::httpd::site { 'wikinews':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikinews.conf',
        priority => 11,
    }

    ::httpd::site { 'loginwiki':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/loginwiki.conf',
        priority => 12,
    }

    ::httpd::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikimedia.conf',
        priority => 16,
    }

    ::httpd::site { 'wikivoyage':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/wikivoyage.conf',
        priority => 17,
    }

    ::httpd::site { 'remnant':
        ensure   => absent,
        priority => 20,
    }

}
