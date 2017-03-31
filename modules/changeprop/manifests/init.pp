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
# [*restbase_uri*]
#   RESTBase's URI. Note that this is redefined here so that async update
#   requests can be sent to the inactive DC. Default:
#   'http://restbase.svc.eqiad.wmnet:7231'
#
# [*ores_uris*]
#   A list of urls for the ORES service. Defaults to:
#   [http://ores.svc.eqiad.wmnet:8081, http://ores.svc.codfw.wmnet:8081]
#
class changeprop(
    $broker_list,
    $purge_host   = '239.128.0.112',
    $purge_port   = 4827,
    $restbase_uri = 'http://restbase.svc.eqiad.wmnet:7231',
    $ores_uri     = 'http://ores.svc.eqiad.wmnet:8081',
    $ores_uris    = [
        'http://ores.svc.eqiad.wmnet:8081',
        'http://ores.svc.codfw.wmnet:8081',
    ],
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
            restbase_uri => $restbase_uri,
            ores_uri     => $ores_uri,
            ores_uris    => $ores_uris,
            purge_host   => $purge_host,
            purge_port   => $purge_port,
            site         => $::site,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128,
        },
    }

}
