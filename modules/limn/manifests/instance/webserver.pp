# == Define limn::instance::webserver
# Sets up an apache proxy for proxying to a Limn instance.
#
# == Parameters:
# $port          - Apache port to Listen on.
# $dest          - URI to proxy to.  This should be the Limn instance.  Default: http://127.0.0.1:8081
# $servername    - Named VirtualHost.  Default: ''
# $serveraliases - Server name aliases.  Default: ''
#
define limn::instance::webserver (
  $port          = 80,
  $dest          = 'http://127.0.0.1:8081',
  $servername    = '',
  $serveraliases = '')
{
  include apache,
    apache::mod::proxy,
    apache::mod::proxy_http

  apache::vhost::proxy { "limn-${name}":
    port          => $port,
    dest          => $dest,
    servername    => $servername,
    serveraliases => $serveraliases,
  }
}
