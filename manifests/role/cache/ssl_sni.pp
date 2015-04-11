class role::cache::ssl_sni {
    #TODO: kill the old wmf_ca
    include certificates::wmf_ca
    include certificates::wmf_ca_2014_2017
    include role::protoproxy::ssl::common

    role::cache::localssl { 'unified':
        certname => 'uni.wikimedia.org',
        default_server => true,
        do_ocsp => true,
    }

    define role::cache::ssl_sni::sni_cert() {
        role::cache::localssl { $name:
            certname => "sni.${name}",
            server_name => $name,
            server_aliases => ["*.${name}"],
            do_ocsp => true,
        }
    }

    role::cache::ssl_sni::sni_cert { 'zero.wikipedia.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikipedia.org':; }
    role::cache::ssl_sni::sni_cert { 'wikipedia.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikimedia.org':; }
    role::cache::ssl_sni::sni_cert { 'wikimedia.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wiktionary.org':; }
    role::cache::ssl_sni::sni_cert { 'wiktionary.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikiquote.org':; }
    role::cache::ssl_sni::sni_cert { 'wikiquote.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikibooks.org':; }
    role::cache::ssl_sni::sni_cert { 'wikibooks.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikisource.org':; }
    role::cache::ssl_sni::sni_cert { 'wikisource.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikinews.org':; }
    role::cache::ssl_sni::sni_cert { 'wikinews.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikiversity.org':; }
    role::cache::ssl_sni::sni_cert { 'wikiversity.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikidata.org':; }
    role::cache::ssl_sni::sni_cert { 'wikidata.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikivoyage.org':; }
    role::cache::ssl_sni::sni_cert { 'wikivoyage.org':; }
    role::cache::ssl_sni::sni_cert { 'm.wikimediafoundation.org':; }
    role::cache::ssl_sni::sni_cert { 'wikimediafoundation.org':; }
    role::cache::ssl_sni::sni_cert { 'm.mediawiki.org':; }
    role::cache::ssl_sni::sni_cert { 'mediawiki.org':; }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_sslxNN',
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
