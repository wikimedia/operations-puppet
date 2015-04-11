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

    sni_cert { 'zero.wikipedia.org':; }
    sni_cert { 'm.wikipedia.org':; }
    sni_cert { 'wikipedia.org':; }
    sni_cert { 'm.wikimedia.org':; }
    sni_cert { 'wikimedia.org':; }
    sni_cert { 'm.wiktionary.org':; }
    sni_cert { 'wiktionary.org':; }
    sni_cert { 'm.wikiquote.org':; }
    sni_cert { 'wikiquote.org':; }
    sni_cert { 'm.wikibooks.org':; }
    sni_cert { 'wikibooks.org':; }
    sni_cert { 'm.wikisource.org':; }
    sni_cert { 'wikisource.org':; }
    sni_cert { 'm.wikinews.org':; }
    sni_cert { 'wikinews.org':; }
    sni_cert { 'm.wikiversity.org':; }
    sni_cert { 'wikiversity.org':; }
    sni_cert { 'm.wikidata.org':; }
    sni_cert { 'wikidata.org':; }
    sni_cert { 'm.wikivoyage.org':; }
    sni_cert { 'wikivoyage.org':; }
    sni_cert { 'm.wikimediafoundation.org':; }
    sni_cert { 'wikimediafoundation.org':; }
    sni_cert { 'm.mediawiki.org':; }
    sni_cert { 'mediawiki.org':; }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_sslxNN',
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
