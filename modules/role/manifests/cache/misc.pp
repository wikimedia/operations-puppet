class role::cache::misc {
    system::role { 'cache::misc':
        description => 'misc Varnish cache server',
    }

    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::misc

    # Temp. experiment to duplicate/mirror the webrequest data
    # to the new Kafka Jumbo brokers.
    include ::profile::cache::kafka::webrequest::jumbo
}
