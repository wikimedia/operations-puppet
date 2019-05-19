class mediawiki::web::beta_sites {
    tag 'mediawiki', 'mw-apache-config'

    # w-beta.wmflabs.org depends on proxy_http
    httpd::mod_conf { 'proxy_http':
        ensure => present,
    }

    mediawiki::web::vhost { 'testwikimedia':
        server_aliases  => ['test.wikimedia.beta.wmflabs.org'],
        docroot         => '/srv/mediawiki/docroot/wikimedia.org',
        declare_site    => false,
        short_urls      => false,
        public_rewrites => true,
    }

    ::httpd::site { 'beta-specific':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/beta_specific.conf',
        priority => 1,
    }

    ::httpd::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/beta/sites/main.conf',
        priority => 1,
    }

    mediawiki::web::vhost {
        default:
            docroot         => '/srv/mediawiki/docroot/standard-docroot',
            legacy_rewrites => false,
            public_rewrites => true,
            short_urls      => false,
            declare_site    => true,
            domain_suffix   => 'beta.wmflabs.org',
            variant_aliases => [
                'sr', 'sr-ec', 'sr-el', 'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-sg', 'zh-tw'
            ],
            ;
        'wikibooks':
            server_aliases => ['*.wikibooks.beta.wmflabs.org'],
            priority       => 2,
            ;
        'wikipedia':
            docroot             => '/srv/mediawiki/docroot/wikipedia.org',
            server_aliases      => ['*.wikipedia.beta.wmflabs.org'],
            priority            => 3,
            additional_rewrites => {
                'early' => [],
                'late'  => [
                    '    # Redirect commons.wikipedia to commons.wikimedia',
                    '    RewriteCond %{HTTP_HOST} =commons.wikipedia.beta.wmflabs.org',
                    '    RewriteRule ^(.*)$ http://commons.wikimedia.beta.wmflabs.org$1 [R=301,L,NE]',
                    '    RewriteRule ^/data/(.*)/(.*)$ /wiki/Special:PageData/$1/$2 [R=303,QSA]'
                ]
            }
            ;
        'wikidata':
            server_aliases      => [
                'wikidata.beta.wmflabs.org',
                '*.wikidata.beta.wmflabs.org'
            ],
            priority            => 4,
            additional_rewrites => {
                'early' => [],
                'late'  => [
                    '    # https://meta.wikimedia.org/wiki/Wikidata/Notes/URI_scheme',
                    '    Include "sites-enabled/wikidata-uris.incl"',
                ]
            }
            ;
        'wikisource':
            server_aliases => ['*.wikisource.beta.wmflabs.org'],
            priority       => 5,
            ;
        'wikiversity':
            server_aliases => ['*.wikiversity.beta.wmflabs.org'],
            priority       => 7,
            ;
        'wikiquote':
            server_aliases => ['*.wikiquote.beta.wmflabs.org'],
            priority       => 8,
            ;
        'wiktionary':
            server_aliases => ['*.wiktionary.beta.wmflabs.org'],
            priority       => 10,
            ;
        'wikinews':
            server_aliases => ['*.wikinews.beta.wmflabs.org'],
            priority       => 11,
            ;
        'loginwiki':
            server_name     => 'login.wikimedia.beta.wmflabs.org',
            public_rewrites => false,
            priority        => 12,
            variant_aliases => [],
            ;
        'wikimedia':
            server_name     => 'misc-sites',
            server_aliases  => [
                'zero.wikimedia.beta.wmflabs.org',
                'commons.wikimedia.beta.wmflabs.org',
                'deployment.wikimedia.beta.wmflabs.org',
                'meta.wikimedia.beta.wmflabs.org',
            ],
            priority        => 16,
            variant_aliases => [],
            ;
        'wikivoyage':
            server_aliases  => ['*.wikivoyage.beta.wmflabs.org'],
            variant_aliases => [
                'zh', 'zh-hans', 'zh-hant',
                'zh-cn', 'zh-hk', 'zh-mo',
                'zh-my', 'zh-sg', 'zh-tw'
            ],
            priority        => 17,
    }

#    ::httpd::site { 'testwiki':
#        ensure   => absent,
#        priority => 9,
#    }

#    ::httpd::site { 'remnant':
#        ensure   => absent,
#        priority => 20,
#    }

}
