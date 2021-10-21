class role::kibana7_ecs {
    system::role { 'kibana7_ecs':
        description => 'ELK7 Kibana ECS host',
    }

    include profile::base::production
    include profile::base::firewall
    include profile::elasticsearch::logstash
    include profile::elasticsearch::monitor::base_checks
    include profile::kibana
    include profile::kibana::httpd_proxy
    include profile::tlsproxy::envoy # TLS termination
}
