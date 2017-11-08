class role::logstash::storage {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver
    include ::profile::logstash::elasticsearch

    system::role { 'logstash::storage':
        ensure      => 'present',
        description => 'elasticsearch data node backing logstash',
    }

}