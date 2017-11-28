# filtertags: labs-project-deployment-prep
class role::mediawiki::appserver {
    system::role { 'mediawiki::appserver': }

    include ::role::mediawiki::webserver
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter

}
