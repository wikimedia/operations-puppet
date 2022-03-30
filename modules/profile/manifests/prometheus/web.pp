class profile::prometheus::web () {

    class { '::httpd':
        modules => ['proxy', 'proxy_http', 'rewrite'],
    }

    profile::auto_restarts::service { 'apache2': }
}
