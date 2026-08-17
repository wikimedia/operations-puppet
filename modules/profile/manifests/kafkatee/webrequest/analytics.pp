# == Class profile::logging::kafkatee::webrequest::analytics
#
# This is a class to help testing a smaller stream
# of webrequests data in the Hadoop Test Cluster.
# More details in: T212259 and T386177
#
class profile::kafkatee::webrequest::analytics (
    String $kafka_cluster_name = lookup('profile::kafkatee::webrequest::analytics::kafka_cluster_name', { 'default_value' => 'jumbo-eqiad' }),
) {
    #kcat is the new name for kafkacat, since bookworm.
    ensure_packages('kcat')

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
        kafka_brokers   => $kafka_config['brokers']['ssl_array'],
        output_encoding => 'json',
        inputs          => [$input_webrequest_text],
        ssl_enabled     => true,
        ssl_ca_location => profile::base::certificates::get_trusted_ca_path(),
    }

    kafkatee::output { 'webrequest-test-output':
        instance_name => 'webrequest-test',
        destination   => "/usr/bin/kcat -P -t webrequest_test_text -b ${kafka_brokers}",
        type          => 'pipe',
        sample        => 1000,
    }

    # Replicate the webrequest_text sampling for the webrequest_frontend_text topic
    # TODO: When the webrequest data is not produced anymore, remove the code above

    # Include only one webrequest_frontend_text topic partition as inputs,
    # since we only need a tiny fraction of the traffic.
    # Note: we used offset => 'end' rather than 'stored'
    # because we don't need to backfill these files from
    # buffered kafka data if kafkatee goes down.
    $input_webrequest_frontend_text = {
        'topic'      => 'webrequest_frontend_text',
        'partitions' => '0',
        'options'    => {
            'encoding' => 'json',
        },
        'offset'     => 'end',
    }

    # Install kafkatee configured to consume from
    # the Kafka cluster with webrequest_frontend logs.
    # The webrequest_frontend logs are in json, so we output
    # them in the format they are received.
    kafkatee::instance { 'webrequest-frontend-test':
        kafka_brokers   => $kafka_config['brokers']['ssl_array'],
        output_encoding => 'json',
        inputs          => [$input_webrequest_frontend_text],
        ssl_enabled     => true,
        ssl_ca_location => profile::base::certificates::get_trusted_ca_path(),
    }

    kafkatee::output { 'webrequest-frontend-test-output':
        instance_name => 'webrequest-frontend-test',
        destination   => "/usr/bin/kcat -P -t webrequest_frontend_test_text -b ${kafka_brokers}",
        type          => 'pipe',
        sample        => 100,
    }
}
