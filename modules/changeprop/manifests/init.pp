# == Class: changeprop
#
# This class installs and configures the change propagation service, a part of
# the EventBus system responsible for reacting to events received via Kafka and
# dispatching the appropriate requests.
#
# === Parameters
#
# [*zk_uri*]
#   The URI (host:port) of the Zookeeper broker(s) controlling the Kafka cluster
#   from which to receive the events.
#
# [*mwapi_uri*]
#   The full URI of the MW API contact point. Default:
#   http://api.svc.${::mw_primary}.wmnet/w/api.php
#
# [*restbase_uri*]
#   The host/IP where to reach RESTBase. Default:
#   http://restbase.svc.${::rb_site}.wmnet:7231
#
# [*concurrency*]
#   The maximum number of tasks the service can execute at any given point in
#   time. Default: 100
#
class changeprop(
    $zk_uri,
    $mwapi_uri    = "http://api.svc.${::mw_primary}.wmnet/w/api.php",
    $restbase_uri = "http://restbase.svc.${::rb_site}.wmnet:7231",
    $concurrency  = 100,
) {

    service::node { 'changeprop':
        enable          => true,
        port            => 7272,
        heap_limit      => 750,
        config          => template('changeprop/config.yaml.erb'),
        starter_module  => 'hyperswitch',
        healthcheck_url => '',
        has_spec        => true,
        deployment      => 'scap3',
        auto_refresh    => false,
        init_restart    => false,
    }

}
