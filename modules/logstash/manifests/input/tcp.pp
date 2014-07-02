# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::tcp
#
# Configure logstash to collect input via a tcp socket.
#
# == Parameters:
# - $ensure: Whether the config should exist. Default 'present'.
# - $port: Port to listen for udp2log input on. Default '5229'.
# - $codec: Codec to decode tcp stream input. Default 'plain'.
# - $priority: Configuration loading priority. Default '10'.
#
# == Sample usage:
#
#   logstash::input::tcp {
#       port  => 5229,
#       codec => 'json_lines',
#   }
#
define logstash::input::tcp(
    $ensure   = present,
    $port     = 5229,
    $codec    = 'plain'
    $priority = 10,
) {
    logstash::conf { "input-tcp-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/tcp.erb'),
        priority => $priority,
    }
}
