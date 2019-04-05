# == Class profile::cache::ssl::wikibase
#
# Sets up TLS termination for a cache host. It can be used either with the old
# letsencrypt puppetisation, in which case you will need to specify the server
# name and other subjects, or with acme-chief.
#
class profile::cache::ssl::wikibase(
    $monitoring=hiera('profile::cache::ssl::wikibase::monitoring'),
    $letsencrypt=hiera('profile::cache::ssl::wikibase::letsencrypt', false),
    $le_server_name=hiera('profile::cache::ssl::wikibase::le_server_name', undef),
    $le_subjects=hiera('profile::cache::ssl::wikibase::le_subjects', undef),
    $ocsp_proxy=hiera('http_proxy', ''),
) {
    if $letsencrypt {
        tlsproxy::localssl { 'wikibase':
            server_name    => $le_server_name,
            acme_subjects  => $le_subjects,
            default_server => false,
            do_ocsp        => false,
            skip_private   => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            redir_port     => 8080,
        }

    } else {
        tlsproxy::localssl { 'wikibase':
            server_name    => 'wikiba.se',
            server_aliases => ['www.wikiba.se'],
            acme_chief     => true,
            default_server => false,
            do_ocsp        => true,
            upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
            redir_port     => 8080,
            ocsp_proxy     => $ocsp_proxy,
        }
    }

    if $monitoring {
        # TODO: this is just good for production of course, we might
        # want to move these variables to hiera
        if $letsencrypt {
            $check = 'check_ssl_unified_sni_letsencrypt_no_ocsp'
        } else {
            $check = 'check_ssl_unified_sni_letsencrypt'
        }
        $check_cn = 'wikiba.se'
        $check_sans = [
            'wikiba.se', 'www.wikiba.se',
        ]

        $check_sans_str = inline_template('<%= @check_sans.join(",") %>')

        monitoring::service { 'wikibase-https-ecdsa':
            description   => 'HTTPS wikibase ECDSA',
            check_command => "${check}!ECDSA!${check_cn}!${check_sans_str}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
        }

        monitoring::service { 'wikibase-https-rsa':
            description   => 'HTTPS wikibase RSA',
            check_command => "${check}!RSA!${check_cn}!${check_sans_str}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
        }
    }
    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
