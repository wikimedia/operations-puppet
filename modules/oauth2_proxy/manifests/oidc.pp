# SPDX-License-Identifier: Apache-2.0

# @summary Provide a stateless (cookie-based) OIDC client reverse proxy for SSO
# @param upstreams The list of URLs to proxy to after authentication
# @param client_id OIDC client ID
# @param client_secret OIDC client secret
# @param cookie_secret The secret to use to encrypt cookies
# @param cookie_domain The domain to set cookies for
# @param redirect_url The OIDC callback url, e.g. https://<your virtual host>/oauth2/callback
# @param email_domain Which email domain to authenticate for
# @param issuer_url The OIDC issuer that will do the authentication
# @param listen_address The host:port to listen on
#
# See also https://oauth2-proxy.github.io/oauth2-proxy/docs/

class oauth2_proxy::oidc (
    Array[String[1]] $upstreams,
    String[1] $client_id,
    Sensitive[String[1]] $client_secret,
    Sensitive[String[1]] $cookie_secret,
    String[1] $cookie_domain,
    Stdlib::HTTPSUrl $redirect_url,
    String[1] $email_domain = 'wikimedia.org',
    Stdlib::HTTPSUrl $issuer_url = 'https://idp.wikimedia.org/oidc',
    String[1] $listen_address = '127.0.0.1:4180',
    Array[String] $skip_auth_routes = [],
) {
    ensure_packages(['oauth2-proxy'])

    if ! ($cookie_secret.unwrap.length in [16, 24, 32]) {
        fail('Cookie secret length must be 16, 24 or 32 bytes')
    }

    service { 'oauth2-proxy':
        ensure => running,
    }

    file { '/etc/oauth2-proxy.cfg':
        ensure    => present,
        owner     => 'oauth2-proxy',
        group     => 'root',
        mode      => '0440',
        content   => template('oauth2_proxy/oidc.erb'),
        notify    => Service['oauth2-proxy'],
        show_diff => false,
        require   => Package['oauth2-proxy'],
    }
}
