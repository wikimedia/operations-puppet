class role::logstash {
    system::role { 'logstash':
      description => 'Logstash, Kibana and Elasticsearch ingest node',
    }
    include profile::standard
    include profile::base::firewall
    include profile::logstash::collector
    include profile::logstash::apifeatureusage
    include profile::prometheus::logstash_exporter
    include profile::tlsproxy::envoy # TLS termination
}
