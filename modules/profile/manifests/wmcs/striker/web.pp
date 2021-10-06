class profile::wmcs::striker::web(
) {
    ensure_packages('libapache2-mod-wsgi-py3')
    class { '::httpd':
        modules => ['alias', 'ssl', 'rewrite', 'headers', 'wsgi',
                    'proxy', 'expires', 'proxy_http', 'proxy_balancer',
                    'lbmethod_byrequests', 'proxy_fcgi'],
    }

    class { '::striker::apache': }
    class { '::striker::uwsgi': }
    require ::passwords::striker
}
