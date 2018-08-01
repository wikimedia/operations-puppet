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

    # Other wikis
    apache::site { 'remnant':
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf',
        priority => 4,
    }

    # Search vhost
    apache::site { 'search.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf',
        priority => 5,
    }

    # Old secure redirects
    apache::site { 'secure.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf',
        priority => 6,
    }

    # Wikimania sites, plus one wiki for wikimaniateam
    apache::site { 'wikimania':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf',
        priority => 7,
    }

    # wikimediafoundation wiki, already a single wiki
    apache::site { 'foundation':
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf',
        priority => 8,
    }

    # Some other wikis, plus loginwiki, and www.wikimedia.org
    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf',
        priority => 9,
    }

    $sites_available = '/etc/apache2/sites-available'
    # Included in main.conf
    $main_conf_sites = [
        'mediawiki.org',
        'test.wikidata.org',
        'wikidata.org',
        'wiktionary.org',
        'wikiquote.org',
        'donate.wikimedia.org',
        'vote.wikimedia.org',
        'wikipedia.org',
        'wikibooks.org',
        'wikisource.org',
        'wikinews.org',
        'wikiversity.org',
        'wikivoyage.org'
    ]
    mediawiki::web::site { $main_conf_sites:
        before => Apache::Site['main']
    }

    # Remnant related wikis
    $remnant_conf_sites = [
        'meta.wikimedia.org',
        '_wikisource.org',
        'commons.wikimedia.org',
        'incubator.wikimedia.org',
        'species.wikimedia.org',
        'usability.wikimedia.org',
        'strategy.wikimedia.org',
        'advisory.wikimedia.org',
        'quality.wikimedia.org',
        'outreach.wikimedia.org'
    ]
    mediawiki::web::site { $remnant_conf_sites:
        before => Apache::Site['remnant']
    }

    # private wikis in remnant.conf; they all change just by ServerName
    $small_private_wikis = [
        'internal.wikimedia.org', 'grants.wikimedia.org', 'fdc.wikimedia.org',
        'board.wikimedia.org', 'boardgovcom.wikimedia.org', 'spcom.wikimedia.org',
        'affcom.wikimedia.org', 'searchcom.wikimedia.org',
        'office.wikimedia.org', 'chair.wikimedia.org',
        'auditcom.wikimedia.org', 'otrs-wiki.wikimedia.org',
        'exec.wikimedia.org', 'collab.wikimedia.org',
        'movementroles.wikimedia.org', 'checkuser.wikimedia.org',
        'steward.wikimedia.org', 'ombudsmen.wikimedia.org',
        'projectcom.wikimedia.org', 'techconduct.wikimedia.org',
        'electcom.wikimedia.org', 'advisors.wikimedia.org'
    ]
    mediawiki::web::site { $small_private_wikis:
        template_name => 'private-https',
        before        => Apache::Site['remnant'],
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
