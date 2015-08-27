# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::udp
#
# Configure logstash to collect input via UDP and the json codec.
#
# == Parameters:
# - $ensure: Whether the config should exist. Default 'present'.
# - $type: Type field to add to all events. Default $title.
# - $port: Port to listen for udp2log input on. Default '11514'.
# - $codec: Codec to decode tcp stream input. Default 'plain'.
# - $priority: Configuration loading priority. Default '10'.
#
# == Sample usage:
#
#   logstash::input::udp { 'logback':
#       port  => 11514,
#       codec => 'json',
#   }
#
define logstash::input::udp(
    $ensure   = present,
    $type     = $title,
    $port     = 11514,
    $codec    = 'plain',
    $priority = 10,
) {
    logstash::conf { "input-udp-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/udp.erb'),
        priority => $priority,
    }
}
