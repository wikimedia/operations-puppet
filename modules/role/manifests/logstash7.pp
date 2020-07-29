class role::logstash7 {
    system::role { 'logstash7':
        description => 'ELK7 Logstash/Kibana host',
    }

    include profile::standard
    include profile::base::firewall
    include profile::logstash::collector7
    include profile::elasticsearch::logstash
    include profile::elasticsearch::monitor::base_checks
    include profile::kibana
    include profile::kibana::httpd_proxy
    include profile::prometheus::logstash_exporter
    include profile::tlsproxy::envoy # TLS termination
    include profile::lvs::realserver
}
