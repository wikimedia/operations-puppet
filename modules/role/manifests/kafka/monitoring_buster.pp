# temporary fork of role::kafka::monitoring to prevent duplicate metrics
# remove during cut-over/replacment of kafkamon[12]001

class role::kafka::monitoring_buster {

    system::role { 'kafka::monitoring_buster':
        description => 'Kafka consumer groups lag monitoring (temporary fork for buster upgrade)'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::kafka::monitoring
}
