# phabricator instance
#
# filtertags: labs-project-deployment-prep labs-project-phabricator
class role::phabricator {

    system::role { 'phabricator':
        description => 'Phabricator (Main) Server'
    }

    include ::profile::standard
    include ::lvs::realserver
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::phabricator::main
    include ::profile::phabricator::httpd
    include ::profile::phabricator::monitoring
    include ::profile::prometheus::apache_exporter
    include ::profile::rsyslog::kafka_shipper
    include ::profile::waf::apache2::administrative
}
