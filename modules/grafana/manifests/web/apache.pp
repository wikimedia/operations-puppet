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
# === Examples
#
#  class { '::grafana::web::apache':
#    server_name => 'grafana.wikimedia.org',
#  }
#
class grafana::web::apache(
    $server_name,
    $ensure = present,
    $listen = '*:80',
) {
    apache::site { 'grafana':
        ensure  => $ensure,
        content => template('grafana/grafana.apache.erb'),
    }
}
