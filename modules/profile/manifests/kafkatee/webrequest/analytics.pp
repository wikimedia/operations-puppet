# == Class profile::logging::kafkatee::webrequest::analytics
#
# This is a temporary class to help testing a smaller stream
# of webrequests data in the Hadoop Test Cluster.
# More details in: T212259
#
class profile::kafkatee::webrequest::analytics(
    $kafka_cluster_name = hiera('profile::kafkatee::webrequest::analytics::kafka_cluster_name', 'jumbo-eqiad'),
    $kafka_target_topic = hiera('profile::kafkatee::webrequest::analytics::kafka_target_topic', 'webrequest_test_text'),
) {
    require_package('kafkacat')

    $kafka_config = kafka_config($kafka_cluster_name)
    $kafka_brokers = $kafka_config['brokers']['string']

    # Include only one webrequest topic partition as inputs,
    # since we only need a tiny fraction of the traffic.
    # Note: we used offset => 'end' rather than 'stored'
    # because we don't need to backfill these files from
    # buffered kafka data if kafkatee goes down.
    $input_webrequest_text = {
        'topic'      => 'webrequest_text',
        'partitions' => '0',
        'options'    => {
            'encoding' => 'json',
        },
        'offset'     => 'end',
    }

    # Install kafkatee configured to consume from
    # the Kafka cluster with webrequest logs.  The webrequest logs are
    # in json, so we output them in the format they are received.
    kafkatee::instance { 'webrequest-test':
        kafka_brokers   => $kafka_config['brokers']['array'],
        output_encoding => 'json',
        inputs          => [$input_webrequest_text],
    }

    kafkatee::output { 'webrequest-test-output':
        instance_name => 'webrequest-test',
        destination   => "/usr/bin/kafkacat -P -t ${kafka_target_topic} -b ${kafka_brokers}",
        type          => 'pipe',
        sample        => 1000,
    }
}
