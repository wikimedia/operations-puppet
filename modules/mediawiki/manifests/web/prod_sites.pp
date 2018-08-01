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

    apache::site { 'foundation':
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf',
        priority => 8,
    }

    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf',
        priority => 9,
    }

    $sites_available = '/etc/apache2/sites-available'
    # Included in main.conf
    $main_conf_sites = [
        'mediawiki.org',
        'test.wikidata.org',
    ]
    mediawiki::web::site { $main_conf_sites:
        before => Apache::Site['main']
    }


    mediawiki::web::site { 'wikimaniateam.wikimedia.org':
        before => Apache::Site['wikimania']
    }
    mediawiki::web::site {[
        'wikimedia-chapter',
        'login.wikimedia.org',
        'www.wikimedia.org'
    ]:
        before => Apache::Site['wikimedia']
    }
    $other_wikis = [
        'transitionteam.wikimedia.org', 'iegcom.wikimedia.org',
        'legalteam.wikimedia.org', 'zero.wikimedia.org'
    ]
    mediawiki::web::site { $other_wikis:
        template_name => 'private-https',
        before        => Apache::Site['wikimedia'],
    }
}
