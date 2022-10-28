# SPDX-License-Identifier: Apache-2.0
# A webserver configured for a CI master, as proxy
class profile::ci::httpd {

    $php_version = debian::codename::eq('buster') ? {
        true    => '7.3',
        default => '7.0',
    }

    $httpd_php_package = "libapache2-mod-php${php_version}"
    $httpd_php_module = "php${php_version}"

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
}
