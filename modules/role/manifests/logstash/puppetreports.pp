# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::puppetreports
#
# Set up a TCP listener to listen for puppet failure reports.
#
# filtertags: labs-project-deployment-prep
class role::logstash::puppetreports {
    system::role { 'logstash::puppetreports':
      description => 'Logstash, Kibana and Elasticsearch ingest node for puppet reports',
    }
    include profile::standard
    include profile::base::firewall
    include profile::logstash::collector
    include profile::elasticsearch::logstash
    include profile::elasticsearch::monitor::base_checks
    include profile::logstash::puppetreports
    include profile::logstash::apifeatureusage
}
