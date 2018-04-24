# Compound role for analytics kafka brokers.
#
# This 'analytics_a' role is temporary, and will be removed after
# The Kafka analytics cluster is decomissioned.
# It exists so we can selectively apply hiera differently
# to profile::kafka::mirror to mirror from main -> analytics.
#
class role::kafka::analytics_a {
    system::role { 'kafka_analytics': }

    include ::role::kafka::analytics::broker
    include ::profile::kafka::mirror

    include ::standard
    include ::base::firewall
}
