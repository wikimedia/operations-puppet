class role::mediawiki::appserver {
    system::role { 'mediawiki::appserver': }
    include ::profile::base::production
    include ::role::mediawiki::common

    include ::profile::base::firewall
    include ::profile::prometheus::apache_exporter
    include ::profile::mediawiki::php::monitoring
    include ::profile::mediawiki::webserver
    # restart php-fpm if the opcache available is too low
    include ::profile::mediawiki::php::restarts
}
