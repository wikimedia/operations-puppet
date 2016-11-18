# == Class role::cache::kafka
# Base class for instances of varnishkafka on cache servers.
#
class role::cache::kafka {

    $kafka_config = kafka_config('analytics')
    # NOTE: This is used by inheriting classes role::cache::kafka::*
    $kafka_brokers = $kafka_config['brokers']['array']

    apt::pin { 'varnishkafka':
        ensure   => 'absent',
        pin      => '',
        priority => '',
    }

    # Make the Varnishkafka class depend on APT pinning. We want to ensure
    # varnishkafka is not apt-get installed before the pinning file is
    # created/removed.
    Apt::Pin['varnishkafka'] -> Class['Varnishkafka']

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance <| |>
}
