# graphite production server with performance web site
class role::graphite::primary {
    include ::role::graphite::production
    include ::role::performance::site

    class { '::httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http', 'uwsgi', 'authnz_ldap'],
    }
}
