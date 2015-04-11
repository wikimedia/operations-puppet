class role::cache::ssl_sni {
    #TODO: kill the old wmf_ca
    include certificates::wmf_ca
    include certificates::wmf_ca_2014_2017
    include role::protoproxy::ssl::common

    role::cache::ssl::local { 'unified':
        certname => 'uni.wikimedia.org',
        default_server => true,
        do_ocsp => true,
    }

    # local shorthand for use below only
    define sni_cert() {
        role::cache::ssl::local { $name:
            certname => "sni.${name}",
            server_name => $name,
            server_aliases => ["*.${name}"],
            do_ocsp => true,
        }
    }

    sni_cert {
        'zero.wikipedia.org':;
        'm.wikipedia.org':;
        'wikipedia.org':;
        'm.wikimedia.org':;
        'wikimedia.org':;
        'm.wiktionary.org':;
        'wiktionary.org':;
        'm.wikiquote.org':;
        'wikiquote.org':;
        'm.wikibooks.org':;
        'wikibooks.org':;
        'm.wikisource.org':;
        'wikisource.org':;
        'm.wikinews.org':;
        'wikinews.org':;
        'm.wikiversity.org':;
        'wikiversity.org':;
        'm.wikidata.org':;
        'wikidata.org':;
        'm.wikivoyage.org':;
        'wikivoyage.org':;
        'm.wikimediafoundation.org':;
        'wikimediafoundation.org':;
        'm.mediawiki.org':;
        'mediawiki.org':;
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_sslxNN',
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
