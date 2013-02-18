# == Define limn::instance::webserver
# Sets up an apache proxy for proxying to a Limn instance.
#
# == Parameters:
# $port          - Apache port to Listen on.
# $limn_host     - host or IP of Limn instnace.  Default: 127.0.0.1
# $limn_port     - port of Limn instance. Default: 8081
# $servername    - Named VirtualHost.  Default: $name.wikimedia.org if production, $name.wmflabs.org if labs, '' if neither.
# $serveraliases - Server name aliases.  Default: ''
#
define limn::instance::webserver (
  $port          = 80,
  $limn_host     = '127.0.0.1',
  $limn_port     = '8081',
  $servername    = undef,
  $serveraliases = '')
{
  include apache,
    apache::mod::proxy,
    apache::mod::proxy_http

  # If we weren't given specific ServerName
  # then assume the one based on the current
  # WMF puppet realm.
  if ($servername == undef) {
    $server_name = $::realm ? {
      'labs'        => "${name}.wmflabs.org",
      'production'  => "${name}.wikimedia.org",
      default       => '',
    }
  }

  apache::vhost::proxy { "limn-${name}":
    port          => $port,
    dest          => "http://${limn_host}:${limn_port}",
    servername    => $server_name,
    serveraliases => $serveraliases,
  }
}
