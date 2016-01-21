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
# [*cassandra_defaultConsistency*]
#   Default cassandra query consistency level. Typically 'one' or
#   'localQuorum'. Default: 'localQuorum'.
#
# [*cassandra_localDc*]
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
# [*parsoid_uri*]
#   URI to reach Parsoid. Default: http://parsoid-lb.eqiad.wikimedia.org
#
# [*logstash_host*]
#   GELF logging host. Default: localhost
#
# [*logstash_port*]
#   GELF logging port. Default: 12201
#
# [*logging_level*]
#   The logging level. One of ['trace','debug','info','warn','error','fatal']
#   Default: 'warn'
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
# [*monitor_domain*]
#   The domain to monitor during the service's operation.
#   Default: en.wikipedia.org
#
class restbase(
    $cassandra_user = 'cassandra',
    $cassandra_password = 'cassandra',
    $seeds          = [$::ipaddress],
    $cassandra_defaultConsistency = 'localQuorum',
    $cassandra_localDc = 'datacenter1',
    $cassandra_datacenters = [ 'datacenter1' ],
    $port           = 7231,
    $salt_key       = 'secretkey',
    $page_size      = 250,
    $config_template = 'restbase/config.yaml.erb',
    $parsoid_uri    = 'http://parsoid-lb.eqiad.wikimedia.org',
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $logging_level  = 'warn',
    $statsd_host    = 'localhost',
    $statsd_port    = '8125',
    $graphoid_uri   = 'http://graphoid.svc.eqiad.wmnet:19000',
    $mobileapps_uri = 'http://mobileapps.svc.eqiad.wmnet:8888',
    $mathoid_uri    = 'http://mathoid.svc.eqiad.wmnet:10042',
    $aqs_uri        =
    'http://aqs.svc.eqiad.wmnet:7232/analytics.wikimedia.org/v1',
    $monitor_domain = 'en.wikipedia.org',
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
        init_restart    => false,
    }

}
