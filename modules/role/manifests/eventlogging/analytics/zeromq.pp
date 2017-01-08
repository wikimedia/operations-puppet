# == Class role::eventlogging::analytics::zeromq
# Runs an eventlogging-forwarder to forward events from
# the Kafka topic eventlogging-valid-mixed to a zeromq
# Pub/Sub port, so that webperf zeromq consumers keep working.
#
# This class exists only for backwards compatibility for services
# consuming from the legacy ZMQ stream now.
class role::eventlogging::analytics::zeromq {
    include role::eventlogging::analytics::server

    $eventlogging_host    = hiera('eventlogging_host', $::ipaddress)

    $kafka_mixed_uri = $role::eventlogging::analytics::server::kafka_mixed_uri

    # This forwards the kafka eventlogging-valid-mixed topic to
    # ZMQ port 8600 for backwards compatibility.
    eventlogging::service::forwarder { 'legacy-zmq':
        input   => "${kafka_mixed_uri}&enable_auto_commit=False&identity=eventlogging_legacy_zmq",
        outputs => ["tcp://${eventlogging_host}:8600"],
    }

    ferm::service { 'eventlogging-zmq-legacy-stream':
        proto   => 'tcp',
        notrack => true,
        port    => '8600',
        srange  => '@resolve((hafnium.eqiad.wmnet graphite1001.eqiad.wmnet))',
    }
}
