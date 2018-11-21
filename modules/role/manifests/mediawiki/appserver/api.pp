class role::mediawiki::appserver::api {
    system::role { 'mediawiki::appserver::api': }
    include standard
    include ::role::mediawiki::common

    include ::profile::base::firewall
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::profile::prometheus::php_fpm_exporter
    include ::profile::mediawiki::webserver
    include ::profile::mediawiki::api
}
