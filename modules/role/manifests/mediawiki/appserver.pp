# filtertags: labs-project-deployment-prep
class role::mediawiki::appserver {
    system::role { 'role::mediawiki::appserver': }

    include ::role::mediawiki::webserver
    include ::role::prometheus::apache_exporter
    include ::role::prometheus::hhvm_exporter

}
