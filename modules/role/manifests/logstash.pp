class role::logstash {
    system::role { 'logstash': }
    include ::role::logstash::collector
    include ::role::kibana
    include ::role::logstash::apifeatureusage
    include ::profile::prometheus::logstash_exporter
}
