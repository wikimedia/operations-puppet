# == Class profile::eventlogging::analytics::server
#
# Common profile class that all other eventlogging analytics profile classes should include.
#
# Note:
# We ensure that python-kafka for eventlogging is at 1.4.1. There is an upstream bug:
#   - https://github.com/dpkp/kafka-python/issues/1418.
# Our apt repo (as of 2019-09) has python-kafka 1.4.6 for use with coal. We want to ensure we
# don't accidentally upgrade on eventloggging until this is fixed.
# See also: https://phabricator.wikimedia.org/T222941
#
class profile::eventlogging::analytics::server(
    $kafka_cluster = lookup('profile::eventlogging::analytics::server::kafka_cluster'),
    $python_kafka_version = lookup('profile::eventlogging::analytics::python_kafka_version', { 'default_value' => '1.4.1-1~stretch1' }),
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
        eventlogging_path    => '/srv/deployment/eventlogging/analytics',
        log_dir              => '/srv/log/eventlogging/systemd',
        python_kafka_version => $python_kafka_version,
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

