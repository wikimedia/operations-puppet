# SPDX-License-Identifier: Apache-2.0

# @summary OIDC-based SSO support for Thanos

class profile::thanos::oidc (
    Hash[Stdlib::Fqdn, Hash]   $rule_hosts = lookup('profile::thanos::rule_hosts'),
    Sensitive[String] $client_secret = lookup('profile::thanos::oidc::client_secret'),
    Sensitive[String] $cookie_secret = lookup('profile::thanos::oidc::cookie_secret'),
    String $public_domain = lookup('public_domain'),
) {
    $virtual_host = "thanos.${public_domain}"

    # oauth2-proxy supports only one upstream per path, thus pick either
    # a single rule host, or the site rule host
    $rule_hostnames = keys($rule_hosts)
    if $rule_hostnames.length == 1 {
        $rule_host = $rule_hostnames[0]
    } else {
        $rule_host = filter($rule_hostnames) |$h| {
            $h =~ $::site
        }[0]
    }

    if empty($rule_host) {
        fail("Unable to pick a rule host amongst ${rule_hosts}")
    }

    # non-root upstream with and without the trailing slash is needed to
    # make sure path-based routing works as expected.
    $upstreams = [
      'http://localhost:16902/',
      'http://localhost:15902/bucket',
      'http://localhost:15902/bucket/',
      "http://${rule_host}:17902/rule",
      "http://${rule_host}:17902/rule/",
    ]

    class { 'profile::oauth2_proxy::oidc':
        upstreams     => $upstreams,
        client_id     => 'thanos_oidc',
        client_secret => $client_secret,
        cookie_secret => $cookie_secret,
        cookie_domain => $virtual_host,
        redirect_url  => "https://${virtual_host}/oauth2/callback",
    }

    httpd::site { 'thanos-oidc':
        content => template('profile/thanos/oidc.conf.erb'),
    }
}
