# == Class: graphite::web::nginx
#
# Configures Nginx to act as a reverse proxy for Graphite.
#
# === Parameters
#
# [*server_name*]
#   Name of virtual server. May contain wildcards.
#   See <http://nginx.org/en/docs/http/server_names.html>.
#   Defaults to '_', which is catch-all.
#
# === Examples
#
#  class { 'graphite::web::nginx':
#    server_name => 'graphite.wikimedia.org',
#  }
#
class graphite::web::nginx(
    $ensure      = present,
    $server_name = '_',
) {
    nginx::site { 'graphite':
        ensure  => $ensure,
        content => template('graphite/graphite.nginx.erb'),
    }
}

