# == Class: rcstream::proxy
#
# This class provisions an Nginx WebSockets reverse-proxy.
# Requires Nginx 1.4+.
#
# === Parameters
#
# [*backends*]
#   An array of port numbers or strings in 'host:port' format
#   specifying the WebSocket backend servers to reverse-proxy.
#
# [*server_name*]
#   See <http://nginx.org/en/docs/http/server_names.html>.
#   Defaults to '_'.
#
# [*listen*]
#   Interface / port to listen on (default: 80).
#   See <http://nginx.org/en/docs/http/ngx_http_core_module.html#listen>.
#
# [*location*]
#   Path WebSocket servers should be mounted at (default: '/').
#
# === Examples
#
#  class { '::rcstream::proxy':
#    server_name => 'stream.wikimedia.org',
#    listen      => 8080,
#    location    => '/rc',
#    backends    => [
#      'websockets.eqiad.wmnet:10080',
#      'websockets.eqiad.wmnet:10081',
#      'websockets.eqiad.wmnet:10082',
#    ],
#  }
#
class rcstream::proxy(
    $backends,
    $ensure      = present,
    $server_name = '_',
    $listen      = 80,
    $location    = '/',
) {
    nginx::site { 'rcstream':
        content => template('rcstream/rcstream.nginx.erb'),
    }
}
