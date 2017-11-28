# == Class role::eventstreams
#
# Role class for EventStreams HTTP service.
# This class includes the ::eventstreams role, and configures
# it to consume only specific topics from a specific Kafka cluster.
#
class role::eventstreams {
    system::role { 'eventstreams':
        description => 'Exposes configured event streams from Kafka to public internet via HTTP SSE',
    }
    include ::profile::eventstreams
}
