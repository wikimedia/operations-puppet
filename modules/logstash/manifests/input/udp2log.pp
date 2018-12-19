# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::udp2log
#
# Configure logstash to collect input as a udp2log relay listener.
#
# == Parameters:
# - $port: port to listen for udp2log input on
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::input::udp2log {
#       port => 8324,
#   }
#
define logstash::input::udp2log(
    $ensure    = present,
    $port      = 8324,
    $priority  = 10,
    $plugin_id = "input/udp2log/${port}",
    $tags      = undef,
) {
    logstash::conf { "input-udp2log-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/udp2log.erb'),
        priority => $priority,
    }
}
