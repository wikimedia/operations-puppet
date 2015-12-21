# == Class role::cache::kafka
# Base class for instances of varnishkafka on cache servers.
#
class role::cache::kafka {
    require role::kafka::analytics::config
    $kafka_brokers = $::role::kafka::analytics::config::brokers_array

    # Make sure varnishkafka rsyslog file is in place properly.
    rsyslog::conf { 'varnishkafka':
        source   => 'puppet:///files/varnish/varnishkafka_rsyslog.conf',
        priority => 70,
    }

    # Make sure that Rsyslog::Conf['varnishkafka'] happens
    # before the first varnishkafka::instance
    # so that logs will go to rsyslog the first time puppet
    # sets up varnishkafka.
    Rsyslog::Conf['varnishkafka'] -> Varnishkafka::Instance <|  |>

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance <| |>
}
