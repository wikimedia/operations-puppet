class role::logstash::frontend {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver
    include ::profile::logstash::elasticsearch
    include ::profile::logstash::collector
    include ::profile::logstash::apifeatureusage
    include ::profile::kibana

    system::role { 'logstash::frontend':
        ensure      => 'present',
        description => 'logstash frontend',
    }

}
