# == Class: editstream::proxy
#
# This class provisions an Nginx WebSockets reverse-proxy
# and load balancer. It requires Nginx 1.4+.
#
# For a comparison of WebSockets-capable load balancers,
# see <https://github.com/observing/balancerbattle>.
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
#  class { '::editstream::proxy':
#    server_name => 'stream.wikimedia.org',
#    listen      => 8080,
#    location    => '/edits',
#    backends    => [
#      'websockets.eqiad.wmnet:10080',
#      'websockets.eqiad.wmnet:10081',
#      'websockets.eqiad.wmnet:10082',
#    ],
#  }
#
# === Further reading ===
#
# * <http://nginx.org/en/docs/http/websocket.html>
# * <http://siriux.net/2013/06/nginx-and-websockets/>
#
class editstream::proxy(
    $backends,
    $ensure      = present,
    $server_name = '_',
    $listen      = 80,
    $location    = '/',
) {
    nginx::site { 'editstream':
        content => template('editstream/editstream.nginx.erb'),
    }
}
