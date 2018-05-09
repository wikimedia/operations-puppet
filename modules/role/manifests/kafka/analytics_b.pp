# Compound role for analytics kafka brokers.
#
# This 'analytics_b' role is temporary, and will be removed after
# The Kafka analytics cluster is decomissioned.
# It exists so we can selectively apply hiera differently
# to profile::kafka::mirror to mirror from main -> jumbo.
#
class role::kafka::analytics_b {
    system::role { 'kafka_analytics': }

    include ::role::kafka::analytics::broker

    include ::standard
    include ::base::firewall
}
