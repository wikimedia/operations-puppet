# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::beats
#
# Configure logstash to collect input from filebeats application
#
# == Parameters:
# - $ensure: Whether the config should exist.
# - $port: Log4j socket port. Default 5044
# - $priority: Configuration loading priority. Default '10'.
#
# == Sample usage:
#
#   logstash::inputs::beats { 'beats':
#   }
#
define logstash::input::beats(
    $ensure     = present,
    $port       = 5044,
    $priority   = 10,
) {
    logstash::conf { "input-beats-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/beats.erb'),
        priority => $priority,
    }
}
