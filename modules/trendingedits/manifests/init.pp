# == Class: trendingedits
#
# This class installs and configures the trending edits service, which follows
# events from the EventBus system in real time and computes the list of
# currently-trending articles based on the number of edits.
#
# === Parameters
#
# [*port*]
#   The port to bind the service to
#
# [*broker_list*]
#   Comma-separated list of Kafka broker URIs
#
class trendingedits(
    $port,
    $broker_list,
) {

    require ::trendingedits::packages

    service::node { 'trendingedits':
        port              => $port,
        repo              => 'trending-edits/deploy',
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            broker_list => $broker_list,
            site        => $::site,
        },
        environment       => {
            'UV_THREADPOOL_SIZE' => 16,
        },
    }

}
