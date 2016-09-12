# == Class: changeprop
#
# This class installs and configures the change propagation service, a part of
# the EventBus system responsible for reacting to events received via Kafka and
# dispatching the appropriate requests.
#
# === Parameters
#
# [*broker_list*]
#   Comma-separated list of Kafka broker URIs
#
# [*purge_host*]
#   The vhtcpd daemon host to send purge requests to. Default: 239.128.0.112
#
# [*purge_port*]
#   The port the vhtcp daemon listens to. Default: 4827
#
# [*ores_uri*]
#   The host where ORES service is running. Default: http://ores.svc.eqiad.wmnet:8081
#
class changeprop(
    $broker_list,
    $purge_host   = '239.128.0.112',
    $ores_uri     = 'http://ores.svc.eqiad.wmnet:8081',
    $purge_port   = 4827,
) {

    include ::service::configuration

    require ::changeprop::packages

    service::node { 'changeprop':
        enable            => true,
        port              => 7272,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            broker_list  => $broker_list,
            mwapi_uri    => $::service::configuration::mwapi_uri,
            restbase_uri => $::service::configuration::restbase_uri,
            ores_uri     => $ores_uri,
            purge_host   => $purge_host,
            purge_port   => $purge_port,
            site         => $::site,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128
        },
    }

}
