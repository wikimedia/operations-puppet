# Compound role for analytics kafka
class role::kafka::analytics {
    system::role { 'kafka_analytics': }
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }

    include ::role::kafka::analytics::broker
    # Mirror all other Kafka cluster data into the analytics Kafka cluster.
    if $::hostname =~ /kafka10(12|13|14)/ {
        include ::role::kafka::analytics::mirror
    }

    # Mirror main Kafka cluster data to Jumbo Kafka cluster.
    # NOTE:  this is only running on the analytics Kafka brokers because
    # of a 0.11 client compatibility issue.  Ideally this class would
    # be included on the jumbo brokers instead.  But, since we need to consume
    # from a 0.9 cluster (main), we need to use a non 0.11 MirrorMaker version,
    # which is not available on the Kafka jumbo brokers, since they are 0.11.
    if $::hostname =~ /kafka10(20|22|23)/ {
        include ::profile::kafka::mirror
    }

    include ::role::ipsec
    include ::standard
    include ::base::firewall
}
