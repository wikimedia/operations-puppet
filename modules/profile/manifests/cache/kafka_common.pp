# == Class profile::cache::kafka
# Profile class for parameters common to all varnishkafka profiles
#
class profile::cache::kafka_common {

    $kafka_config = kafka_config('analytics')
    # NOTE: This is used by inheriting classes role::cache::kafka::*
    $kafka_brokers = $kafka_config['brokers']['array']

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance <| |>
}
