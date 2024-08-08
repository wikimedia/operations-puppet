# SPDX-License-Identifier: Apache-2.0

class profile::prometheus::web_idp (
    Enum['cas', 'oidc'] $auth_type = lookup('profile::prometheus::web_idp::auth_type', { 'default_value' => 'cas' }),
    Optional[Sensitive[String]] $oidc_client_secret = lookup('profile::prometheus::web_idp::oidc_client_secret', { 'default_value' => undef }),
    Optional[Sensitive[String]] $oidc_cookie_secret = lookup('profile::prometheus::web_idp::oidc_cookie_secret', { 'default_value' => undef }),
    Stdlib::HTTPSUrl $oidc_issuer_url = lookup('profile::prometheus::web_idp::oidc_issuer_url', { 'default_value' => 'https://idp.wikimedia.org/oidc' }),
    String $public_domain = lookup('public_domain'),
) {
    include ::profile::tlsproxy::envoy

    $vhost = "prometheus-${::site}.${public_domain}"

    if ($auth_type == 'cas') {
        profile::idp::client::httpd::site { $vhost:
            vhost_content    => 'profile/idp/client/httpd-prometheus.erb',
            proxied_as_https => true,
            document_root    => '/var/www/html',
            required_groups  => [
                'cn=nda,ou=groups,dc=wikimedia,dc=org',
                'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            ],
        }
    }

    if ($auth_type == 'oidc') {
        class { 'profile::oauth2_proxy::oidc':
            upstreams     => ['http://localhost'],
            client_id     => 'prometheus_oidc',
            client_secret => $oidc_client_secret,
            cookie_secret => $oidc_cookie_secret,
            issuer_url    => $oidc_issuer_url,
            cookie_domain => $vhost,
            redirect_url  => "https://${vhost}/oauth2/callback",
        }

        # auth_cas needs to be disabled now: apache won't start with the module
        # enabled and no CAS directives configured.
        # MOD_AUTH_CAS: CASLoginURL or CASValidateURL not defined. AH00016: Configuration Failed
        httpd::mod_conf { 'auth_cas':
            ensure => absent,
        }

        httpd::site { $vhost:
            content  => template('profile/prometheus/httpd-public.conf.erb'),
            priority => 20,
        }
    }
}
