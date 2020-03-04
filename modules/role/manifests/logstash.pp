class role::logstash {
    system::role { 'logstash':
      description => 'Logstash, Kibana and Elasticsearch ingest node',
    }
    include ::role::logstash::collector
    include ::role::kibana
    include ::role::logstash::apifeatureusage
    include ::profile::prometheus::logstash_exporter
    include ::profile::tlsproxy::envoy # TLS termination
}
