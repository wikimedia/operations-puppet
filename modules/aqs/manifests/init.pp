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
class aqs(
    $cassandra_user = 'cassandra',
    $cassandra_password = 'cassandra',
    $seeds          = [$::ipaddress],
    $cassandra_defaultConsistency = 'localQuorum',
    $cassandra_localDc = 'datacenter1',
    $cassandra_datacenters = [ 'datacenter1' ],
    $port           = 7232,
    $salt_key       = 'secretkey',
    $page_size      = 250,
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $logging_level  = 'warn',
    $statsd_host    = 'localhost',
    $statsd_port    = 8125,
) {

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
