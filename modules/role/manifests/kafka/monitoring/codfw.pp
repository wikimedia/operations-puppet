class role::kafka::monitoring::codfw {

    system::role { 'kafka::monitoring::codfw':
        description => 'Kafka Consumer Lag Monitoring for codfw clusters'
    }

    include ::profile::kafka::burrow::main::codfw
}