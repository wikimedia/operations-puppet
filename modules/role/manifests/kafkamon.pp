# Kafka Burrow Consumer lag monitoring (T187901, T187805)
class role::kafkamon {

    system::role { 'Kafka monitoring':
        description => 'Kafka Burrow Consumer lag monitoring server'
    }

    include ::standard
    include ::profile::base::firewall

    include ::profile::kafka::burrow::analytics
    include ::profile::kafka::burrow::main::eqiad
    include ::profile::kafka::burrow::main::codfw
}
