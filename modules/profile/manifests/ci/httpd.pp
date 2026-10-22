# SPDX-License-Identifier: Apache-2.0
# A webserver configured for a CI master, as proxy
class profile::ci::httpd {
    include profile::ci

    # headers: Need to send Vary: X-Forwarded-Proto since most sites are
    # forced to HTTPS and behind a varnish cache. See also T62822
    #
    # proxy/proxy_http: for Jenkins and Zuul proxied behind httpd
    class { 'httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http',
                    'ssl'
        ],
    }

    profile::auto_restarts::service { 'apache2': }
}
