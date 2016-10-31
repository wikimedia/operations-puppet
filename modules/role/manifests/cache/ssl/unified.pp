class role::cache::ssl::unified(
    $labs_server_name = 'beta.wmflabs.org',
    $labs_subjects = ['beta.wmflabs.org'],
) {
    if ( $::realm == 'production' ) {

        $check_cn = 'en.wikipedia.org'
        $check_sans = [
            'wikipedia.org',
            'mediawiki.org',
            'wikibooks.org',
            'wikidata.org',
            'wikimedia.org',
            'wikimediafoundation.org',
            'wikinews.org',
            'wikiquote.org',
            'wikisource.org',
            'wikiversity.org',
            'wikivoyage.org',
            'wiktionary.org',
            'w.wiki',
            '*.wikipedia.org',
            '*.mediawiki.org',
            '*.wikibooks.org',
            '*.wikidata.org',
            '*.wikimedia.org',
            '*.wikimediafoundation.org',
            '*.wikinews.org',
            '*.wikiquote.org',
            '*.wikisource.org',
            '*.wikiversity.org',
            '*.wikivoyage.org',
            '*.wiktionary.org',
            '*.m.wikipedia.org',
            '*.m.mediawiki.org',
            '*.m.wikibooks.org',
            '*.m.wikidata.org',
            '*.m.wikimedia.org',
            '*.m.wikimediafoundation.org',
            '*.m.wikinews.org',
            '*.m.wikiquote.org',
            '*.m.wikisource.org',
            '*.m.wikiversity.org',
            '*.m.wikivoyage.org',
            '*.m.wiktionary.org',
            '*.zero.wikipedia.org'
        ]

        $check_sans_str = inline_template('<%= @check_sans.join(",") %>')

        monitoring::service { 'https':
            description   => 'HTTPS Unified ECDSA',
            check_command => "check_ssl_unified!ECDSA!${check_cn}!${check_sans_str}",
        }

        monitoring::service { 'https':
            description   => 'HTTPS Unified RSA',
            check_command => "check_ssl_unified!RSA!${check_cn}!${check_sans_str}",
        }

        tlsproxy::localssl { 'unified':
            server_name    => 'www.wikimedia.org',
            certs          => ['ecc-uni.wikimedia.org', 'uni.wikimedia.org'],
            default_server => true,
            do_ocsp        => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            redir_port     => 8080,
        }
    }
    else {
        tlsproxy::localssl { 'unified':
            server_name    => $labs_server_name,
            acme_subjects  => $labs_subjects,
            default_server => true,
            do_ocsp        => false,
            skip_private   => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            redir_port     => 8080,
        }
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
