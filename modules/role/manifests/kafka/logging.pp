class role::kafka::logging {

    include ::profile::kafka::broker
    system::role { 'kafka::logging':
        description => "Kafka Broker in the logging-${::site} Kafka cluster",
    }

    include ::profile::base::firewall
    include ::profile::standard
}
