class role::mediawiki::appserver::api {
    system::role { 'mediawiki::appserver::api': }

    include ::role::mediawiki::webserver
    include ::profile::base::firewall
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::profile::mediawiki::api
}
