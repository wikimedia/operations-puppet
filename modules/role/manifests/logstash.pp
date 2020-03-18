class role::logstash {
    system::role { 'logstash':
      description => 'Logstash, Kibana and Elasticsearch ingest node',
    }
    include ::role::logstash::collector
    include ::role::logstash::apifeatureusage
    include ::profile::kibana
    include ::profile::kibana::httpd_proxy
    include ::profile::prometheus::logstash_exporter
    include ::profile::tlsproxy::envoy # TLS termination
}
