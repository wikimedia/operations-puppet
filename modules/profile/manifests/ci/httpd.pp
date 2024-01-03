# SPDX-License-Identifier: Apache-2.0
# A webserver configured for a CI master, as proxy
class profile::ci::httpd {
    include profile::ci
    include profile::ci::php

    $httpd_php_package = "libapache2-mod-php${profile::ci::php::php_version}"
    $httpd_php_module = $profile::ci::php::php_prefix

    ensure_packages($httpd_php_package)

    # headers: Need to send Vary: X-Forwarded-Proto since most sites are
    # forced to HTTPS and behind a varnish cache. See also T62822
    #
    # proxy/proxy_http: for Jenkins and Zuul proxied behind httpd
    class { 'httpd':
        modules => ['headers',
                    'rewrite',
                    $httpd_php_module,
                    'proxy',
                    'proxy_http'
        ],
    }

    profile::auto_restarts::service { 'apache2': }

    if $profile::ci::manager {
        prometheus::blackbox::check::http { 'integration.wikimedia.org':
            team               => 'collaboration-services',
            severity           => 'task',
            path               => '/',
            ip_families        => ['ip4'],
            force_tls          => true,
            port               => 1443,
            body_regex_matches => ['Integration'],
        }
    }
}
