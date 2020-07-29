class role::logstash7 {
    system::role { 'logstash7':
        description => 'ELK7 Logstash/Kibana host',
    }

    include ::role::logstash::collector7
    include ::profile::kibana
    include ::profile::kibana::httpd_proxy
    include ::profile::prometheus::logstash_exporter
    include ::profile::tlsproxy::envoy # TLS termination
    include ::profile::lvs::realserver
}
