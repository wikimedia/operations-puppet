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
# [*purge_host*]
#   The vhtcpd daemon host to send purge requests to. Default: 239.128.0.112
#
# [*purge_port*]
#   The port the vhtcp daemon listens to. Default: 4827
#
# [*concurrency*]
#   The maximum number of tasks the service can execute at any given point in
#   time. Default: 100
#
class changeprop(
    $zk_uri,
    $purge_host   = '239.128.0.112',
    $purge_port   = 4827,
    $concurrency  = 100,
) {

    include ::service::configuration

    $restbase_uri = $::service::configuration::restbase_uri
    $mwapi_uri = $::service::configuration::mwapi_uri

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
