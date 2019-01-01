class mediawiki::web::prod_sites(String $fcgi_proxy) {
    tag 'mediawiki', 'mw-apache-config'

    ::httpd::site { 'redirects':
        content  => compile_redirects('puppet:///modules/mediawiki/apache/sites/redirects/redirects.dat'),
        priority => 2,
    }

    # Search vhost
    ::httpd::site { 'search.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf',
        priority => 5,
    }

    # Old secure redirects
    ::httpd::site { 'secure.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf',
        priority => 6,
    }

    ### BEGIN main
    ::httpd::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/sites/main.conf',
        priority => 3,
    }


    # Included in main.conf
    mediawiki::web::vhost{
        default:
            ensure          => present,
            public_rewrites => true,
            declare_site    => false,
            before          => Httpd::Site['main']
            ;
        'test.wikidata.org':
            docroot             => '/srv/mediawiki/docroot/wikidata.org',
            additional_rewrites => {
                'early' => [
                    '    Include "sites-enabled/wikidata-uris.incl"'
                ],
                'late'  => []
            }
            ;
        'wikidata.org':
            docroot             => '/srv/mediawiki/docroot/wikidata.org',
            server_name         => 'www.wikidata.org',
            server_aliases      => ['*.wikidata.org'],
            canonical_name      => 'On',
            additional_rewrites => {
                'early' => [
                    '    Include "sites-enabled/wikidata-uris.incl"'
                ],
                'late'  => []
            },
            legacy_rewrites     => false,
            ;
        'mediawiki.org':
            server_name         => 'www.mediawiki.org',
            docroot             => '/srv/mediawiki/docroot/mediawiki.org',
            server_aliases      => ['download.mediawiki.org'],
            canonical_name      => 'On',
            upload_rewrite      => {
                'rewrite_prefix' => 'mediawiki' },
            additional_rewrites => {
                'early' => [
                    '# Our FAQ',
                    '    RewriteRule ^/FAQ$ %{ENV:RW_PROTO}://www.mediawiki.org/wiki/Help:FAQ [R=301,L]'
                ],
                'late'  => []
            },
            legacy_rewrites     => true
            ;
        'wiktionary.org':
            server_name     => 'wiktionary',
            server_aliases  => ['*.wiktionary.org'],
            docroot         => '/srv/mediawiki/docroot/wiktionary.org',
            short_urls      => true,
            upload_rewrite  => {
                'domain_catchall' => 'wiktionary.org',
                'rewrite_prefix'  => 'wiktionary',
            },
            legacy_rewrites => true,
            variant_aliases => [
                'sr', 'sr-ec', 'sr-el',
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-sg', 'zh-tw'
            ]
            ;
        'wikiquote.org':
            server_name     => 'wikiquote',
            server_aliases  => ['*.wikiquote.org'],
            docroot         => '/srv/mediawiki/docroot/wikiquote.org',
            short_urls      => true,
            upload_rewrite  => {
                'domain_catchall' => 'wikiquote.org',
                'rewrite_prefix'  => 'wikiquote',
            },
            legacy_rewrites => true,
            variant_aliases => [
                'sr', 'sr-ec', 'sr-el',
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-sg', 'zh-tw'
            ],
            ;
        'donate.wikimedia.org':
            docroot             => '/srv/mediawiki/docroot/wikimedia.org',
            server_aliases      => ['donate.wikipedia.org'],
            canonical_name      => 'On',
            https_only          => true,
            legacy_rewrites     => true,
            short_urls          => true,
            additional_rewrites => {
                'early' => [
                    'RewriteRule ^/$ https://donate.wikimedia.org/wiki/Special:FundraiserRedirector [R=302,L]',
                ],
                'late'  => []
            }
            ;
        'vote.wikimedia.org':
            docroot         => '/srv/mediawiki/docroot/wikimedia.org',
            short_urls      => true,
            https_only      => true,
            legacy_rewrites => false,
            ;
        'wikipedia.org':
            server_name         => 'wikipedia',
            server_aliases      => ['*.wikipedia.org'],
            docroot             => '/srv/mediawiki/docroot/wikipedia.org',
            short_urls          => true,
            upload_rewrite      => {
                'domain_catchall' => 'wikipedia.org',
                'rewrite_prefix'  => 'wikipedia',
            },
            legacy_rewrites     => true,
            variant_aliases     => [
                'sr', 'sr-ec', 'sr-el',
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-my',
                'zh-mo', 'zh-sg', 'zh-tw'
            ],
            additional_rewrites => {
                'early' => [],
                'late'  => [
                    '    # moved wikistats off NFS',
                    '    RewriteRule ^/wikistats(/(.*$)|$) %{ENV:RW_PROTO}://stats.wikimedia.org/$2 [R=302,L]'
                ]
            }
            ;
        'wikibooks.org':
            server_name     => 'wikibooks',
            server_aliases  => ['*.wikibooks.org'],
            docroot         => '/srv/mediawiki/docroot/wikibooks.org',
            short_urls      => true,
            upload_rewrite  => {
                'domain_catchall' => 'wikibooks.org',
                'rewrite_prefix'  => 'wikibooks',
            },
            legacy_rewrites => true,
            variant_aliases => [
                'sr', 'sr-ec', 'sr-el',
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-sg', 'zh-tw'
            ],
            ;
        'wikisource.org':
            server_name     => 'wikisource',
            server_aliases  => ['*.wikisource.org'],
            docroot         => '/srv/mediawiki/docroot/wikisource.org',
            short_urls      => true,
            upload_rewrite  => {
                'domain_catchall' => 'wikisource.org',
                'rewrite_prefix'  => 'wikisource',
            },
            legacy_rewrites => true,
            variant_aliases => [
                'sr', 'sr-ec', 'sr-el',
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-sg', 'zh-tw'
            ],
            ;
        'wikinews.org':
            server_name     => 'wikinews',
            server_aliases  => ['*.wikinews.org'],
            docroot         => '/srv/mediawiki/docroot/wikinews.org',
            short_urls      => true,
            upload_rewrite  => {
                'domain_catchall' => 'wikinews.org',
                'rewrite_prefix'  => 'wikinews',
            },
            legacy_rewrites => true,
            variant_aliases => [
                'sr', 'sr-ec', 'sr-el',
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-sg', 'zh-tw'
            ],
            ;
        'wikivoyage.org':
            server_name     => 'wikivoyage',
            server_aliases  => ['*.wikivoyage.org'],
            docroot         => '/srv/mediawiki/docroot/wikivoyage.org',
            variant_aliases => [
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-mo',
                'zh-my', 'zh-sg', 'zh-tw'
            ],
            legacy_rewrites => false,
            ;
        'wikiversity.org':
            server_name     => 'wikiversity',
            server_aliases  => ['*.wikiversity.org'],
            docroot         => '/srv/mediawiki/docroot/wikiversity.org',
            legacy_rewrites => true,
            short_urls      => true,
            upload_rewrite  => {
                'domain_catchall' => 'wikiversity.org',
                'rewrite_prefix'  => 'wikiversity'
            },
            variant_aliases => [
                'sr', 'sr-ec', 'sr-el',
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-sg', 'zh-tw'
            ],
    }
    ### END main

    ### BEGIN remnant
    # Other wikis
    ::httpd::site { 'remnant':
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf',
        priority => 4,
    }

    $remnant_simple_wikis = [
        'outreach.wikimedia.org',
        'advisory.wikimedia.org',
        'quality.wikimedia.org',
        'strategy.wikimedia.org',
        'incubator.wikimedia.org',
    ]

    mediawiki::web::vhost {
        default:
            ensure          => present,
            short_urls      => false,
            docroot         => '/srv/mediawiki/docroot/wikimedia.org',
            legacy_rewrites => true,
            declare_site    => false,
            public_rewrites => true,
            before          => Httpd::Site['remnant'],
            ;
        $remnant_simple_wikis:
            short_urls => true,
            ;
        'usability.wikimedia.org':
            short_urls      => false,
            ;
        'species.wikimedia.org':
            upload_rewrite => {
                'rewrite_prefix' => 'wikipedia/species'
            }
            ;
        'commons.wikimedia.org':
            legacy_rewrites     => true,
            upload_rewrite      => {
                'rewrite_prefix' => 'wikipedia/commons'
            },
            additional_rewrites => {

                'early' => [],
                'late'  => [
                    '    # /data/ path T163922',
                    '    RewriteRule ^/data/(.*)/(.*)$ %{ENV:RW_PROTO}://commons.wikimedia.org/wiki/Special:PageData/$1/$2 [R=301,QSA]'
                ],
            }
            ;
        'meta.wikimedia.org':
            short_urls          => true,
            legacy_rewrites     => true,
            upload_rewrite      => {
                'rewrite_prefix' => 'wikipedia/meta'
            },
            additional_rewrites => {
                'early' => [],
                'late'  => [
                    '    # Used for Firefox OS web application manifest living on meta.wikimedia.org',
                    '    AddType application/x-web-app-manifest+json .webapp'
                ],
            }
            ;
        'test-commons.wikimedia.org':
            legacy_rewrites     => true,
            upload_rewrite      => {
                'rewrite_prefix' => 'wikipedia/testcommons'
            },
            additional_rewrites => {

                'early' => [],
                'late'  => [
                    '    # /data/ path T163922',
                    '    RewriteRule ^/data/(.*)/(.*)$ %{ENV:RW_PROTO}://test-commons.wikimedia.org/wiki/Special:PageData/$1/$2 [R=301,QSA]'
                ],
            }
            ;
        '_wikisource.org':
            docroot        => '/srv/mediawiki/docroot/wikisource.org',
            server_name    => 'wikisource.org',
            upload_rewrite => {
                'rewrite_prefix' => 'wikipedia/sources'
            }
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
    mediawiki::web::vhost { $small_private_wikis:
        ensure          => present,
        docroot         => '/srv/mediawiki/docroot/wikimedia.org',
        legacy_rewrites => false,
        https_only      => true,
        declare_site    => false,
        short_urls      => true,
        before          => Httpd::Site['remnant'],
    }

    ### END remnant

    ### BEGIN wikimania
    # Wikimania sites, plus one wiki for wikimaniateam
    ::httpd::site { 'wikimania':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf',
        priority => 7,
    }

    ## Configuration for wikimania.conf
    mediawiki::web::vhost {
        default:
            ensure          => present,
            docroot         => '/srv/mediawiki/docroot/wikimedia.org',
            legacy_rewrites => false,
            declare_site    => false,
            before          => Httpd::Site['wikimania'],
            ;
        'wikimaniateam.wikimedia.org':
            https_only => true,
            short_urls => true,
            ;
        'wikimania':
            server_aliases => [
                'wikimania.wikimedia.org', 'wikimania2005.wikimedia.org',
                'wikimania2006.wikimedia.org', 'wikimania2007.wikimedia.org',
                'wikimania2008.wikimedia.org', 'wikimania2009.wikimedia.org',
                'wikimania2010.wikimedia.org', 'wikimania2011.wikimedia.org',
                'wikimania2012.wikimedia.org', 'wikimania2013.wikimedia.org',
                'wikimania2014.wikimedia.org', 'wikimania2015.wikimedia.org',
                'wikimania2016.wikimedia.org', 'wikimania2017.wikimedia.org',
                'wikimania2018.wikimedia.org'],
            upload_rewrite => {
                    'domain_catchall' => 'wikimedia.org',
                    'rewrite_prefix'  => 'wikipedia',
            },
    }
    ### END wikimania

    ### BEGIN foundation
    # wikimediafoundation wiki, already a single wiki
    mediawiki::web::vhost { 'foundation':
        server_name         => 'foundation.wikimedia.org',
        server_aliases      => ['wikimediafoundation.org'],
        canonical_name      => 'On',
        docroot             => '/srv/mediawiki/docroot/wikimediafoundation.org',
        declare_site        => true,
        priority            => 8,

        additional_rewrites => {
            'early' => [
                '# extract.php pages redirected to new pages',
                '    RewriteRule ^/fundraising(\.html)?$ %{ENV:RW_PROTO}://%{SERVER_NAME}/wiki/Fundraising [R=301,L]',
                '    RewriteRule ^/index(\.html)?$ %{ENV:RW_PROTO}://%{SERVER_NAME}/wiki/Home [R=301,L]',
                '    RewriteRule ^/GNU_FDL(\.html)?$ %{ENV:RW_PROTO}://%{SERVER_NAME}/wiki/GNU_Free_Documentation_License [R=301,L]',
                '    # Obsolete PDF redirected to current wiki page',
                '    RewriteRule ^/bylaws\.pdf %{ENV:RW_PROTO}://%{SERVER_NAME}/wiki/Wikimedia_Foundation_bylaws [R,L]',
                '    RewriteRule ^/wiki/Donate$ https://donate.wikimedia.org/ [R=301,L]'
            ],
            'late'  => [],
        },
    }

    ### END foundation

    #### BEGIN wikimedia
    # Some other wikis, plus loginwiki, and www.wikimedia.org
    ::httpd::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf',
        priority => 9,
    }


    mediawiki::web::site { 'www.wikimedia.org':
        fcgi_proxy => $fcgi_proxy,
        before     => Httpd::Site['wikimedia']
    }

    $other_wikis = [
        'transitionteam.wikimedia.org', 'iegcom.wikimedia.org',
        'legalteam.wikimedia.org', 'zero.wikimedia.org',
        'fixcopyright.wikimedia.org'
    ]
    mediawiki::web::vhost {
        default:
            ensure          => present,
            docroot         => '/srv/mediawiki/docroot/wikimedia.org',
            legacy_rewrites => false,
            declare_site    => false,
            short_urls      => true,
            before          => Httpd::Site['wikimedia'],
            ;
        $other_wikis:
            https_only => true,
            short_urls => true,
            ;
        'login.wikimedia.org':
            ;
        'wikimedia-chapter':
            server_aliases      => [
                'ar.wikimedia.org',
                'am.wikimedia.org',
                'bd.wikimedia.org',
                'be.wikimedia.org',
                'br.wikimedia.org',
                'ca.wikimedia.org',
                'cn.wikimedia.org',
                'co.wikimedia.org',
                'dk.wikimedia.org',
                'ec.wikimedia.org',
                'ee.wikimedia.org',
                'fi.wikimedia.org',
                'hi.wikimedia.org',
                'id.wikimedia.org',
                'id-internal.wikimedia.org',
                'il.wikimedia.org',
                'mai.wikimedia.org',
                'mk.wikimedia.org',
                'mx.wikimedia.org',
                'nl.wikimedia.org',
                'no.wikimedia.org',
                'noboard-chapters.wikimedia.org',
                'nyc.wikimedia.org',
                'nz.wikimedia.org',
                'pa-us.wikimedia.org',
                'pl.wikimedia.org',
                'pt.wikimedia.org',
                'punjabi.wikimedia.org',
                'romd.wikimedia.org',
                'rs.wikimedia.org',
                'ru.wikimedia.org',
                'se.wikimedia.org',
                'tr.wikimedia.org',
                'ua.wikimedia.org',
                'us.wikimedia.org',
                'wb.wikimedia.org',
                'za.wikimedia.org',
            ],
            legacy_rewrites     => true,
            upload_rewrite      => {
                'domain_catchall' => 'wikimedia.org',
                'rewrite_prefix'  => 'wikimedia.org',
            },
            additional_rewrites => {
                'early' => [
                    '# www. prefix',
                    'RewriteCond %{HTTP_HOST} ^www.([a-z\-]+)\.wikimedia\.org$',
                    'RewriteRule ^(.*)$ %{ENV:RW_PROTO}://%1.wikimedia.org$1 [R=301,L]'
                ],
                'late'  => []
            }
    }

    ### END wikimedia
}
