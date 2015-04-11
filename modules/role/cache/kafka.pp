# == Class role::cache::kafka
# Base class for instances of varnishkafka on cache servers.
#
class role::cache::kafka {
    require role::analytics::kafka::config

    # Get a list of kafka brokers for the currently configured $kafka_cluster_name.
    # In production this will be 'eqiad' always, since we only have one Kafka cluster there.
    # Even though $kafka_cluster_name should hardcoded to 'eqiad' in ...kafka::config,
    # we hardcode it again here, just to be sure it doesn't accidentally get changed
    # if we add new Kafka clusters later.
    $kafka_cluster_name = $::realm ? {
        'production' => 'eqiad',
        'labs'       => $role::analytics::kafka::config::kafka_cluster_name,
    }

    $kafka_brokers = keys($role::analytics::kafka::config::cluster_config[$kafka_cluster_name])

    # varnishkafka will use a local statsd instance for
    # using logster to collect metrics.
    include role::cache::statsd

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
