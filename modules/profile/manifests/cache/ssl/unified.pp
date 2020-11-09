# == Class profile::cache::ssl::unified
#
# Sets up TLS termination for a cache host. It can be used both with letsencrypt
# and with a certificate from a commercial vendor (typically when a unified,
# multiple-wildcard cert is needed, as in production).
#
class profile::cache::ssl::unified(
    Stdlib::Port $tls_port=lookup('profile::cache::ssl::unified::tls_port', {default_value => 443}),
    Boolean $monitoring=lookup('profile::cache::ssl::unified::monitoring'),
    Boolean $acme_chief=lookup('profile::cache::ssl::unified::acme_chief'),
    Array $certs_hiera=lookup('profile::cache::ssl::unified::certs', {default_value => []}),
    Array $certs_active_hiera=lookup('profile::cache::ssl::unified::certs_active', {default_value => []}),
    Boolean $letsencrypt=lookup('profile::cache::ssl::unified::letsencrypt'),
    String $ucv=lookup('public_tls_unified_cert_vendor', {default_value => undef}),
    Optional[String] $le_server_name=lookup('profile::cache::ssl::unified::le_server_name', {default_value => undef}),
    Array $le_subjects=lookup('profile::cache::ssl::le_subjects', {default_value => []}),
    String $ocsp_proxy = lookup('http_proxy', {default_value => ''}),
    Boolean $use_trafficserver_tls = lookup('profile::cache::ssl::unified::use_trafficserver_tls', {default_value => false}),
) {
    if $use_trafficserver_tls {
        $redir_port = undef
    } else {
        $redir_port = 8080
    }

    if $letsencrypt {
        tlsproxy::localssl { 'unified':
            server_name    => $le_server_name,
            acme_subjects  => $le_subjects,
            default_server => true,
            do_ocsp        => false,
            skip_private   => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            tls_port       => $tls_port,
            redir_port     => $redir_port,
            ocsp_proxy     => $ocsp_proxy,
        }

    } else {
        if $certs_active_hiera {
            $certs_active = $certs_active_hiera
        } else {
            $certs_active = [
                "${ucv}-ecdsa-unified", "${ucv}-rsa-unified",
            ]
        }

        $certs = $certs_hiera.empty? {
          true    => ['globalsign-2019-ecdsa-unified', 'globalsign-2019-rsa-unified',
                      'digicert-2020-ecdsa-unified', 'digicert-2020-rsa-unified'],
          default => $certs_hiera,
        }

        tlsproxy::localssl { 'unified':
            server_name    => 'www.wikimedia.org',
            certs          => $certs,
            certs_active   => $certs_active,
            acme_chief     => $acme_chief,
            default_server => true,
            do_ocsp        => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            tls_port       => $tls_port,
            redir_port     => $redir_port,
            ocsp_proxy     => $ocsp_proxy,
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
