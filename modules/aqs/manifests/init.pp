# == Class: aqs
#
# AQS is the Analytics Query Service, a service serving page view data
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
#   Port where to run the AQS service. Default: 7232
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
# [*druid_scheme*]
#   druid scheme. Default: http
#
# [*druid_host*]
#   druid host. Default: druid1004.eqiad.wmnet
#
# [*druid_port*]
#   druid broker port. Default: 8082
#
# [*druid_query_path*]
#   druid broker query path. Default: /druid/v2/
#
include ::passwords::aqs::druid_http_auth
class aqs(
    $cassandra_user = 'cassandra',
    $cassandra_password = 'cassandra',
    $seeds          = [$::ipaddress],
    $cassandra_default_consistency = 'localQuorum',
    $cassandra_local_dc            = 'datacenter1',
    $cassandra_datacenters         = [ 'datacenter1' ],
    $port                          = 7232,
    $salt_key                      = 'secretkey',
    $page_size                     = 250,
    $logstash_host                 = 'localhost',
    $logstash_port                 = 12201,
    $logging_level                 = 'warn',
    $statsd_host                   = 'localhost',
    $statsd_port                   = 8125,
    $druid_scheme                  = 'http',
    $druid_host                    = 'druid1004.eqiad.wmnet',
    $druid_port                    = 8082,
    $druid_query_path              = '/druid/v2/',
) {
    # NOTE: didn't know how to make the ::passwords::aqs values, they're in the private repo, right?

    service::node { 'aqs':
        port            => $port,
        repo            => 'analytics/aqs/deploy',
        config          => template('aqs/config.yaml.erb'),
        full_config     => true,
        no_file         => 200000,
        healthcheck_url => '/analytics.wikimedia.org/v1',
        has_spec        => true,
        local_logging   => false,
        auto_refresh    => false,
        init_restart    => false,
        deployment      => 'scap3',
    }

}
