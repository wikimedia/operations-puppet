# == Class role::kafka::jumbo::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    system::role { 'role::kafka::jumbo::broker':
        description => "Kafka Broker in a 'jumbo' Kafka cluster",
    }
    interface::add_ip6_mapped { 'main': }

    # Something in labs is including standard.  Only include if not already defined.
    if !defined(Class['::standard']) {
        include ::standard
    }
    include base::firewall
    include profile::kafka::broker

    # Mirror from other Kafka cluster to jumbo.
    # TODO:  The new 0.11 Kafka MirrorMaker doesn't work with Kafka Brokers < 0.9.
    # Kafka main clusters are still on 0.9, so we can't colocate MirrorMaker alongside
    # of the newer 0.11 brokers in the jumbo cluster.  We want to do this, but we have
    # to wait until the main Kafka clusters are upgraded, which might be a while.
    # For now, we mirror main cluster topics to jumbo by including
    # role::kafka::jumbo::mirror elsewhere on nodes with older Kafka client versions.
    # include profile::kafka::mirror
}
