class role::kafka::logging {

    system::role { 'kafka::logging':
        description => "Kafka Broker in the logging-${::site} Kafka cluster",
    }

    include profile::firewall
    include profile::base::production
    include profile::kafka::broker
}
