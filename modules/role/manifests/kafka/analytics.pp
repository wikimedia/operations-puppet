# Kafka analytics broker.
# To Be Decommissioned:
#
# Blocked on https://phabricator.wikimedia.org/T175461
#
class role::kafka::analytics {
    system::role { 'kafka_analytics': }

    include ::role::kafka::analytics::broker

    include ::profile::standard
    include ::profile::base::firewall
}
