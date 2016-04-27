
# == Class: changeprop
#
# This class installs and configures the change propagation service, a part of
# the EventBus system responsible for reacting to events received via Kafka and
# dispatching the appropriate requests.
#
# === Parameters
#
# [*logging_name*]
#   The logging name. Default: changeprop
#
# [*logging_level*]
#   The logging level. One of ['trace','debug','info','warn','error','fatal']
#   Default: 'warn'
#
# [*logstash_host*]
#   GELF logging host. Default: localhost
#
# [*logstash_port*]
#   GELF logging port. Default: 12201
#
# [*statsd_prefix*]
#   statsd metric prefix. Default: restbase
#
# [*statsd_host*]
#   statsd host name. Default: localhost
#
# [*statsd_port*]
#   statsd port. Default: 8125
#
# [*restbase_uri*]
#   The host/IP where to reach RESTBase. Default: http://restbase.svc.${::rb_site}.wmnet:7231
#
# [*mwapi_uri*]
#   The host/IP where to reach the MW API. Default: http://api.svc.${::mw_primary}.wmnet/w/api.php
#
# [*zk_uri*]
#   The URI (host:port) of the Zookeeper broker(s) controlling the Kafka cluster
#   from which to receive the events.
#

class changeprop(
    $logging_name  = 'changeprop',
    $logging_level = 'warn',
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $statsd_prefix  = 'changeprop',
    $statsd_host    = 'localhost',
    $statsd_port    = '8125',
    $restbase_uri = "http://restbase.svc.${::rb_site}.wmnet:7231",
    $mwapi_uri    = "http://api.svc.${::mw_primary}.wmnet/w/api.php",
    $zk_uri,
) {

    service::node { 'changeprop':
        port            => 7272,
        config          => template('changeprop/config.yaml.erb'),
        healthcheck_url => '',
        has_spec        => true,
        deployment      => 'scap3',
    }

}
