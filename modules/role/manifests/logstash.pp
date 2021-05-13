class role::logstash {
    system::role { 'logstash':
      description => 'Logstash, Kibana and Elasticsearch ingest node',
    }
    include profile::standard
    include profile::base::firewall
    include profile::logstash::collector
    include profile::logstash::apifeatureusage
    include profile::elasticsearch::logstash
    include profile::elasticsearch::monitor::base_checks
    include profile::kibana
    include profile::kibana::httpd_proxy
    include profile::prometheus::logstash_exporter
    include profile::tlsproxy::envoy # TLS termination
}
