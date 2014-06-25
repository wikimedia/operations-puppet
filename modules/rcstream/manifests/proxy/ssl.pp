# == Class: rcstream::proxy::ssl
#
# This class provisions an Nginx WebSockets reverse-proxy.
# Requires Nginx 1.4+. This class uses SSL to connect to the backend.
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
#   Interface / port to listen on (default: 80, [::]:80),
#   specified as a single value or an array.
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
class rcstream::proxy::ssl(
    $backends,
    $ensure      = present,
    $server_name = '_',
    $listen      = ['443', '[::]:443'],
    $location    = '/'
) {
    $use_ssl = true

    install_certificate {'stream.wikimedia.org':}

    nginx::site { 'rcstream-ssl':
        content => template('rcstream/rcstream.nginx.erb'),
        notify  => Service['nginx'],
        require => Install_certificate['stream.wikimedia.org']
    }

    class {'nginx::ssl':
        ie6_compat => true,
        notify     => Service['nginx']
    }

}
