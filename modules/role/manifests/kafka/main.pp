# Compound role for the Kafka "main" cluster
class role::kafka::main {
    if $::site == 'eqiad' {
        include ::role::kafka::main::broker
    }
    else {
        system::role { 'kafka::main':
            description => "Kafka Broker in the main-${::site} Kafka cluster",
        }
        include ::profile::kafka::broker
    }

    system::role { 'eventbus':
        description => "EventBus HTTP Service node",
    }
    include ::role::eventbus::eventbus

    if $::realm == 'production' {
        # Mirror eqiad.* topics from main-eqiad into main-codfw,
        # or mirror codfw.* topics from main-codfw into main-eqiad.
        system::role { 'kafka::mirror':
            description => "main-* Kafka cluster cross-DC MirrorMaker node",
        }
        include ::profile::kafka::mirror
    }

    include ::standard
}
