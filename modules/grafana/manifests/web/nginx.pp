# == Class: grafana::web::nginx
#
# Configures Nginx to serve Grafana.
#
# === Parameters
#
# [*server_name*]
#   Name of virtual server. May contain wildcards.
#   See <http://nginx.org/en/docs/http/server_names.html>.
#   Defaults to '_', which is catch-all.
#
# [*listen*]
#   Interface / port to listen on (default: 80).
#   See <http://nginx.org/en/docs/http/ngx_http_core_module.html#listen>.
#
# === Examples
#
#  class { 'grafana::web::nginx':
#    server_name => 'grafana.wikimedia.org',
#  }
#
class grafana::web::nginx(
    $ensure      = present,
    $server_name = '_',
    $listen       = 80,
) {
    nginx::site { 'grafana':
        ensure  => $ensure,
        content => template('grafana/grafana.nginx.erb'),
    }
}
