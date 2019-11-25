# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch7 {
    system::role { 'logstash::elasticsearch7':
      description => "Logstash elasticsearch backend node in the production-elk7-${::site} cluster",
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::elasticsearch::logstash
    include ::profile::elasticsearch::monitor::base_checks
}
