# == Class: grafana::web::apache
#
# Configures a dedicated Apache vhost for Grafana.
#
# === Parameters
#
# [*server_name*]
#   Name of virtual server.
#
# [*listen*]
#   Interface / port to listen on (default: "*:80").
#
# [*elastic_backends*]
#   Array of URLs of ElasticSearch backends to use for storage.
#
# === Examples
#
#  class { '::grafana::web::apache':
#    server_name => 'grafana.wikimedia.org',
#  }
#
class grafana::web::apache(
    $server_name,
    $ensure           = present,
    $listen           = '*:80',
    $elastic_backends = undef,
) {
    include ::apache::mod::proxy_balancer

    apache::site { 'grafana':
        ensure  => $ensure,
        content => template('grafana/grafana.apache.erb'),
    }
}
