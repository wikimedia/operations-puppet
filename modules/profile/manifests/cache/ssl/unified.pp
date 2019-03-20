# == Class profile::cache::ssl::unified
#
# Sets up TLS termination for a cache host. It can be used both with letsencrypt
# and with a certificate from a commercial vendor (typically when a unified,
# multiple-wildcard cert is needed, as in production).
#
class profile::cache::ssl::unified(
    $monitoring=hiera('profile::cache::ssl::unified::monitoring'),
    $acme_chief=hiera('profile::cache::ssl::unified::acme_chief'),
    $letsencrypt=hiera('profile::cache::ssl::unified::letsencrypt'),
    $ucv=hiera('public_tls_unified_cert_vendor', undef),
    $le_server_name=hiera('profile::cache::ssl::unified::le_server_name', undef),
    $le_subjects=hiera('profile::cache::ssl::le_subjects', undef)
) {
    if $letsencrypt {
        tlsproxy::localssl { 'unified':
            server_name    => $le_server_name,
            acme_subjects  => $le_subjects,
            default_server => true,
            do_ocsp        => false,
            skip_private   => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            redir_port     => 8080,
        }

    } else {
        # TODO: generalize this a bit?
        $certs_active = [
            "${ucv}-ecdsa-unified", "${ucv}-rsa-unified",
        ]
        # These certs are deployed to all caches and OCSP stapled,
        # ready for use in $certs_active as options
        $certs = [
            'globalsign-2018-ecdsa-unified', 'globalsign-2018-rsa-unified',
        ]
        tlsproxy::localssl { 'unified':
            server_name    => 'www.wikimedia.org',
            certs          => $certs,
            certs_active   => $certs_active,
            acme_chief     => $acme_chief,
            default_server => true,
            do_ocsp        => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            redir_port     => 8080,
        }
    }

    if ( $monitoring ) {
        # TODO: this is just good for production of course, we might
        # want to move these variables to hiera
        $check_cn = 'en.wikipedia.org'
        $check_sans = [
            'wikipedia.org',   '*.wikipedia.org',   '*.m.wikipedia.org',
            'wikimedia.org',   '*.wikimedia.org',   '*.m.wikimedia.org', '*.planet.wikimedia.org',
            'mediawiki.org',   '*.mediawiki.org',   '*.m.mediawiki.org',
            'wikibooks.org',   '*.wikibooks.org',   '*.m.wikibooks.org',
            'wikidata.org',    '*.wikidata.org',    '*.m.wikidata.org',
            'wikinews.org',    '*.wikinews.org',    '*.m.wikinews.org',
            'wikiquote.org',   '*.wikiquote.org',   '*.m.wikiquote.org',
            'wikisource.org',  '*.wikisource.org',  '*.m.wikisource.org',
            'wikiversity.org', '*.wikiversity.org', '*.m.wikiversity.org',
            'wikivoyage.org',  '*.wikivoyage.org',  '*.m.wikivoyage.org',
            'wiktionary.org',  '*.wiktionary.org',  '*.m.wiktionary.org',
            'wikimediafoundation.org', '*.wikimediafoundation.org',
            'wmfusercontent.org', '*.wmfusercontent.org',
            'w.wiki',
        ]

        $check_sans_str = inline_template('<%= @check_sans.join(",") %>')

        monitoring::service { 'https-ecdsa':
            description   => 'HTTPS Unified ECDSA',
            check_command => "check_ssl_unified!ECDSA!${check_cn}!${check_sans_str}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
        }

        monitoring::service { 'https-rsa':
            description   => 'HTTPS Unified RSA',
            check_command => "check_ssl_unified!RSA!${check_cn}!${check_sans_str}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
        }
    }
    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
