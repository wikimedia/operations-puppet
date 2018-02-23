class role::kafka::monitoring {

    system::role { 'kafka::monitoring':
        description => 'Kafka consumer groups lag monitoring'
    }

    include ::profile::kafka::burrow::analytics
    include ::profile::kafka::burrow::main::eqiad
}