class mediawiki::web::beta_sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::site { 'main':
        ensure   => absent,
        priority => 1,
    }

    apache::site { 'wikibooks':
        ensure   => absent,
        priority => 2,
    }

    apache::site { 'wikipedia':
        ensure   => absent,
        priority => 3,
    }

    apache::site { 'wikidata':
        ensure   => absent,
        priority => 4,
    }

    apache::site { 'wikisource':
        ensure   => absent,
        priority => 5,
    }

    apache::site { 'wikiversity':
        ensure   => absent,
        priority => 7,
    }

    apache::site { 'wikiquote':
        ensure   => absent,
        priority => 8,
    }

    apache::site { 'testwiki':
        ensure   => absent,
        priority => 9,
    }

    apache::site { 'wiktionary':
        ensure   => absent,
        priority => 10,
    }

    apache::site { 'wikinews':
        ensure   => absent,
        priority => 11,
    }

    apache::site { 'loginwiki':
        ensure   => absent,
        priority => 12,
    }

    apache::site { 'wikimedia':
        ensure   => absent,
        priority => 16,
    }

    apache::site { 'wikivoyage':
        ensure   => absent,
        priority => 17,
    }

    apache::site { 'remnant':
        ensure   => absent,
        priority => 20,
    }

}
