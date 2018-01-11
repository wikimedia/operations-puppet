# Basic configuration of Apache as a proxy
class profile::ci::proxy_common {

    # Need to send Vary: X-Forwarded-Proto since most sites are forced to HTTPS
    # and behind a varnish cache. See also T62822
    class { '::httpd':
        modules => ['php5', 'proxy', 'proxy_http'],
    }
}
