# Compound role for analytics kafka brokers.
#
# This 'analytics_a' role is temporary, and will be removed after
# The Kafka analytics cluster is decomissioned.
# It exists so we can selectively apply hiera differently
# to profile::kafka::mirror to mirror from main -> analytics.
#
class role::kafka::analytics_a {
    system::role { 'kafka_analytics': }
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }

    include ::role::kafka::analytics::broker
    # TODO: use profile::kafka::broker as part of https://phabricator.wikimedia.org/T192387
    include ::role::kafka::analytics::mirror

    include ::role::ipsec
    include ::standard
    include ::base::firewall
}
