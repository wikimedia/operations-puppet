# == Class: restbase
#
# restbase is a REST API & storage service
# http://restbase.org
#
# === Parameters
#
# [*cassandra_user*]
#   Cassandra user name.
#
# [*cassandra_password*]
#   Cassandra password.
#
# [*seeds*]
#   Array of cassandra hosts (IP or host names) to contact.
#   Default: ['localhost']
#
# [*cassandra_default_consistency*]
#   Default cassandra query consistency level. Typically 'one' or
#   'localQuorum'. Default: 'localQuorum'.
#
# [*cassandra_local_dc*]
#   Which DC should be considered local. Default: 'datacenter1'.
#
# [*cassandra_datacenters*]
#   The full list of member datacenters.
#
# [*port*]
#   Port where to run the restbase service. Default: 7231
#
# [*config_template*]
#   File to use as the configuration file template. Default: restbase/config.yaml.erb
#
# [*skip_updates*]
#   Whether resource_change events should not be emitted by RESTBase. Default: false
#
# [*parsoid_uri*]
#   URI to reach Parsoid. Default: http://parsoid.svc.eqiad.wmnet:8000
#
# [*logstash_host*]
#   GELF logging host. Default: localhost
#
# [*logstash_port*]
#   GELF logging port. Default: 12201
#
# [*logging_name*]
#   The logging name. Default: restbase
#
# [*logging_level*]
#   The logging level. One of ['trace','debug','info','warn','error','fatal']
#   Default: 'warn'
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
# [*graphoid_uri*]
#   graphoid host + port. Default: http://graphoid.svc.eqiad.wmnet:19000
#
# [*mobileapps_uri*]
#   MobileApps service URI. Default: http://mobileapps.svc.eqiad.wmnet:8888
#
# [*mathoid_uri*]
#   Mathoid service URI. Default: http://mathoid.svc.eqiad.wmnet:10042
#
# [*aqs_uri*]
#   Analytics Query Service URI. Default:
#   http://aqs.svc.eqiad.wmnet:7232/analytics.wikimedia.org/v1
#
# [*eventlogging_service_uri*]
#   Eventlogging service URI. Default: http://eventbus.svc.eqiad.wmnet:8085/v1/events
#
# [*monitor_domain*]
#   The domain to monitor during the service's operation.
#   Default: en.wikipedia.org
#
# [*hosts*]
#   The list of RESTBase hosts used for setting up the rate-limiting DHT.
#   Default: [$::ipaddress]
#
class restbase(
    $cassandra_user = 'cassandra',
    $cassandra_password = 'cassandra',
    $seeds          = [$::ipaddress],
    $cassandra_default_consistency = 'localQuorum',
    $cassandra_local_dc = 'datacenter1',
    $cassandra_datacenters = [ 'datacenter1' ],
    $port           = 7231,
    $salt_key       = 'secretkey',
    $page_size      = 250,
    $config_template = 'restbase/config.yaml.erb',
    $skip_updates   = false,
    $parsoid_uri    = 'http://parsoid.svc.eqiad.wmnet:8000',
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $logging_name   = 'restbase',
    $logging_level  = 'warn',
    $statsd_prefix  = 'restbase',
    $statsd_host    = 'localhost',
    $statsd_port    = '8125',
    $graphoid_uri   = 'http://graphoid.svc.eqiad.wmnet:19000',
    $mobileapps_uri = 'http://mobileapps.svc.eqiad.wmnet:8888',
    $mathoid_uri    = 'http://mathoid.svc.eqiad.wmnet:10042',
    $aqs_uri        =
    'http://aqs.svc.eqiad.wmnet:7232/analytics.wikimedia.org/v1',
    $eventlogging_service_uri =
    'http://eventbus.svc.eqiad.wmnet:8085/v1/events',
    $monitor_domain = 'en.wikipedia.org',
    $hosts          = [$::ipaddress],
) {

    service::node { 'restbase':
        port            => $port,
        config          => template($config_template),
        full_config     => true,
        no_file         => 200000,
        healthcheck_url => "/${monitor_domain}/v1",
        has_spec        => true,
        starter_script  => 'restbase/server.js',
        local_logging   => false,
        auto_refresh    => false,
    }

}
