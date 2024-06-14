# == Class role::kafka::jumbo::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    include profile::firewall
    include profile::kafka::broker

    # Temporary workaround to avoid Kafka Mirror failures
    # See T347481
    if $::hostname !~ /^kafka-jumbo100[1-6]/ {
        # Mirror main-eqiad -> jumbo-eqiad
        include profile::kafka::mirror
    }

    include profile::base::production
}
