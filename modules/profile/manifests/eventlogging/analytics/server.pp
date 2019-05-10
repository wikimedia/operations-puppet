# == Class profile::eventlogging::analytics::server
#
# Common profile class that all other eventlogging analytics profile classes should include.
#
class profile::eventlogging::analytics::server(
    $kafka_cluster = hiera('profile::eventlogging::analytics::server::kafka_cluster'),
) {

    scap::target { 'eventlogging/analytics':
        deploy_user => 'eventlogging',
        manage_user => false,
    }

    # Needed because scap::target doesn't manage_user.
    ssh::userkey { 'eventlogging':
        ensure  => 'present',
        content => secret('keyholder/eventlogging.pub'),
    }

    class { 'eventlogging::server':
        eventlogging_path => '/srv/deployment/eventlogging/analytics',
        log_dir           => '/srv/log/eventlogging/systemd',
    }

    # Get the Kafka configuration
    $kafka_config = kafka_config($kafka_cluster)
    $kafka_brokers_string = $kafka_config['brokers']['string']

    # Using kafka-confluent as a consumer is not currently supported by this puppet module,
    # but is implemented in eventlogging.  Hardcode the scheme for consumers for now.
    $kafka_consumer_scheme = 'kafka://'

    # Commonly used Kafka input URIs.
    $kafka_mixed_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topic=eventlogging-valid-mixed&auto_offset_reset=earliest"
    $kafka_client_side_raw_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topic=eventlogging-client-side&auto_offset_reset=earliest"

    eventlogging::plugin { 'plugins':
        source => 'puppet:///modules/eventlogging/plugins.py',
    }

    # make sure any defined eventlogging services are running
    class { '::eventlogging::monitoring::jobs': }
}

