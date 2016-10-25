# == Class: eventstreams
#
# === Parameters
#
# [*broker_list*]
#   Comma-separated list of Kafka broker URIs
#
# [*allowed_topics*]
#   Whitelist of allowed topics.
#
class eventstreams(
    $broker_list,
    $allowed_topics = undef,
) {

    include ::service::configuration

    service::packages { 'eventstreams':
        pkgs     => ['librdkafka++1', 'librdkafka1'],
        dev_pkgs => ['librdkafka-dev'],
    }

    service::node { 'eventstreams':
        enable            => true,
        port              => 6947,
        healthcheck_url   => '',
        has_spec          => false, # I should make one!
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            log_level      => 'info',
            broker_list    => $broker_list,
            allowed_topics => $allowed_topics,
            site           => $::site,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128
        },
    }

}
