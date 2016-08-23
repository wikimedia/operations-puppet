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
# [*concurrency*]
#   The maximum number of tasks the service can execute at any given point in
#   time. Default: 30
#

class changeprop(
    $broker_list,
    $purge_host   = '239.128.0.112',
    $ores_uri     = 'http://ores.svc.eqiad.wmnet:8081',
    $purge_port   = 4827,
    $concurrency  = 50,
) {

    include ::service::configuration

    require ::changeprop::packages

    $restbase_uri = $::service::configuration::restbase_uri
    $mwapi_uri = $::service::configuration::mwapi_uri

    service::node { 'changeprop':
        enable          => true,
        port            => 7272,
        heap_limit      => 750,
        config          => template('changeprop/config.yaml.erb'),
        no_workers      => 8,  # TEMP
        starter_module  => 'hyperswitch',
        healthcheck_url => '',
        has_spec        => true,
        deployment      => 'scap3',
        auto_refresh    => false,
        init_restart    => false,
        environment     => {
            'UV_THREADPOOL_SIZE' => 128
        },
    }

}
