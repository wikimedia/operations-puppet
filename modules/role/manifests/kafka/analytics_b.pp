# Compound role for analytics kafka brokers.
#
# This 'analytics_b' role is temporary, and will be removed after
# The Kafka analytics cluster is decomissioned.
# It exists so we can selectively apply hiera differently
# to profile::kafka::mirror to mirror from main -> jumbo.
#
class role::kafka::analytics_b {
    system::role { 'kafka_analytics': }
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }

    include ::role::kafka::analytics::broker
    include ::profile::kafka::mirror

    include ::standard
    include ::base::firewall
}
