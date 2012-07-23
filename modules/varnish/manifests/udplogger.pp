# Definition: varnish::udplogging
#
# Sets up a UDP logging instances of varnishncsa
#
# Parameters:
# - $title:
#   Name of the instance
# - $host:
#   Hostname or ip address of the logger
# - $port:
#   UDP port (default 8420)
# - $varnish_instance:
#   Varnish instance name (default: undefined)
define varnish::udplogger($host, $port=8420, $varnish_instance=$::hostname) {
  Class[varnish::packages] -> Varnish::Udplogger[$title]
  require varnish::varnishncsa

  $environment = [
    "LOGGER_NAME=${title}",
    "LOG_DEST=\"${host}:${port}\"",
    "VARNISH_INSTANCE=\"-n ${varnish_instance}\""
  ]

  exec { "varnishncsa $title":
    path      => '/bin:/sbin:/usr/bin:/usr/sbin',
    command   => inline_template('start varnishncsa <%= environment.join(" ") %>'),
    unless    => "status varnishncsa LOGGER_NAME=${title}",
    logoutput => true,
  }

  # TODO: monitoring
}
