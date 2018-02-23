class role::kafka::monitoring {

    system::role { 'kafka::monitoring':
        description => 'Kafka consumer groups lag monitoring'
    }

    include ::standard
    include ::profile::base::firewall
    include ::profile::kafka::monitoring
}