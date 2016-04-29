
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
class changeprop(
    $zk_uri,
    $mwapi_uri = "http://api.svc.${::mw_primary}.wmnet/w/api.php",
) {

    service::node { 'changeprop':
        port            => 7272,
        config          => template('changeprop/config.yaml.erb'),
        starter_module  => 'hyperswitch',
        healthcheck_url => '',
        has_spec        => true,
        deployment      => 'scap3',
    }

}
