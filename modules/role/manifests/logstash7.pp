class role::logstash7 {
    system::role { 'logstash7':
        description => 'ELK7 Logstash/Kibana host',
    }

    include ::role::logstash::collector7
    include ::role::kibana
    #include ::role::logstash::apifeatureusage
    include ::profile::prometheus::logstash_exporter
    include ::profile::tlsproxy::envoy # TLS termination
}
