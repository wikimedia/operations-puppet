# == Class profile::cache::ssl::wikibase
#
# Sets up TLS termination for a cache host, with a certificate from acme-chief.
#
class profile::cache::ssl::wikibase(
    $monitoring=hiera('profile::cache::ssl::wikibase::monitoring'),
) {
    tlsproxy::localssl { 'wikibase':
        server_name    => 'wikiba.se',
        server_aliases => ['www.wikiba.se'],
        acme_chief     => true,
        default_server => false,
        do_ocsp        => true,
        upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
        redir_port     => 8080,
    }

    if $monitoring {
        $check_cn = 'wikiba.se'
        $check_sans = [
            'wikiba.se', 'www.wikiba.se',
        ]

        $check_sans_str = inline_template('<%= @check_sans.join(",") %>')

        monitoring::service { 'wikibase-https-ecdsa':
            description   => 'HTTPS wikibase ECDSA',
            check_command => "check_ssl_unified_sni_letsencrypt!ECDSA!${check_cn}!${check_sans_str}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
        }

        monitoring::service { 'wikibase-https-rsa':
            description   => 'HTTPS wikibase RSA',
            check_command => "check_ssl_unified_sni_letsencrypt!RSA!${check_cn}!${check_sans_str}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
        }
    }
    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
