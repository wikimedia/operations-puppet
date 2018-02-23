class role::kafka::monitoring::eqiad {

    system::role { 'kafka::monitoring::eqiad':
        description => 'Kafka Consumer Lag Monitoring for eqiad clusters'
    }

    include ::profile::kafka::burrow::analytics
    include ::profile::kafka::burrow::main::eqiad
}