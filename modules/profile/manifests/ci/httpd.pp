# A webserver configured for a CI master, as proxy
class profile::ci::httpd {

    if os_version('debian == jessie') {
        $php_version = '5'
    } else {
        $php_version = '7.0'
    }

    $httpd_php_package = "libapache2-mod-php${php_version}"
    $httpd_php_module = "php${php_version}"

    require_package($httpd_php_package)

    # headers: Need to send Vary: X-Forwarded-Proto since most sites are
    # forced to HTTPS and behind a varnish cache. See also T62822
    #
    # proxy/proxy_http: for Jenkins and Zuul proxied behind httpd
    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    $httpd_php_module,
                    'proxy',
                    'proxy_http'
        ],
    }
}
