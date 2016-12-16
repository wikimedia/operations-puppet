class role::mediawiki::appserver {
    system::role { 'role::mediawiki::appserver': }

    include ::role::mediawiki::webserver

    # Test of the new HHVM and Apache Prometheus exporters
    # Bug: T147423, T147316
    include ::role::prometheus::apache_exporter
    include ::role::prometheus::hhvm_exporter

}
