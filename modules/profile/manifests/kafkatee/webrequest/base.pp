# == Class role::logging::kafkatee::webrequest
# Uses kafkatee to consume webrequest logs from kafka.
# This class does not configure any kafkatee outputs.
# To do so, you should create a new class that includes
# this class, and configure the outputs there.
#
class profile::kafkatee::webrequest::base(
    Boolean $output_config = lookup('profile::kafkatee::webrequest::base::output_config', {'default_value' => true}),
) {
    $kafka_config = kafka_config('jumbo-eqiad')

    # Include all webrequest topics as inputs.
    # Note:  we used offset => 'end' rather than 'stored'
    # because we don't need to backfill these files from
    # buffered kafka data if kafkatee goes down.
    # These are just logs for ops debugging.
    $input_webrequest_text = {
        'topic'      => 'webrequest_text',
        'partitions' => '0-23',
        'options'    => {
            'encoding' => 'json',
        },
        'offset'     => 'end',
    }
    $input_webrequest_upload = {
        'topic'      => 'webrequest_upload',
        'partitions' => '0-23',
        'options'    => {
            'encoding' => 'json',
        },
        'offset'     => 'end',
    }

    # Install kafkatee configured to consume from
    # the Kafka cluster with webrequest logs.  The webrequest logs are
    # in json, so we output them in the format they are received.
    kafkatee::instance { 'webrequest':
        kafka_brokers   => $kafka_config['brokers']['ssl_array'],
        output_encoding => 'json',
        inputs          => [
            $input_webrequest_text,
            $input_webrequest_upload,
        ],
        output_config   => $output_config,
        ssl_enabled     => true,
        ssl_ca_location => profile::base::certificates::get_trusted_ca_path(),
    }
}
