# https://noc.wikimedia.org/
class noc {

    include ::apache

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    apache::site { 'noc.wikimedia.org':
        content => template('noc/noc.wikimedia.org.erb'),
    }

    # ensure default site is removed
    include ::apache::mod::php5
    include ::apache::mod::userdir
    include ::apache::mod::cgi
    include ::apache::mod::ssl

    # Monitoring
    monitor_service { 'http-noc':
        description   => 'HTTP-noc',
        check_command => 'check_http_url!noc.wikimedia.org!http://noc.wikimedia.org' }

    # caches the ganglia xml data from gmetric used by dbtree every minute
    cron { 'dbtree_cache_cron':
        command => "/usr/bin/curl -s 'http://noc.wikimedia.org/dbtree/?recache=true' >/dev/null",
        user    => 'www-data',
        minute  => '*',
    }
}
