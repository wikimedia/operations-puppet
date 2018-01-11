# Basic configuration of Apache as a proxy
class profile::ci::proxy_common {

    class { '::httpd':
        modules => ['php5', 'proxy', 'proxy_http'],
    }
}
