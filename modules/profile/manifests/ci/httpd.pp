# A webserver configured for a CI master, as proxy
class profile::ci::httpd {

    require_package('libapache2-mod-php5')

    # headers: Need to send Vary: X-Forwarded-Proto since most sites are
    # forced to HTTPS and behind a varnish cache. See also T62822
    #
    # proxy/proxy_http: for Jenkins and Zuul proxied behind httpd
    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    'php5',
                    'proxy',
                    'proxy_http'
        ],
    }
}
