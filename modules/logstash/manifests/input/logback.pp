# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::logback
#
# Configure logstash to collect input via UDP and the json codec.
#
# == Parameters:
# - $port: port to listen for UDP input on
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   logstash::input::logback {
#       port => 11514,
#   }
#
define logstash::input::logback(
    $ensure   = present,
    $port     = 11514,
    $priority = 10,
) {
    logstash::conf { "input-logback-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/logback.erb'),
        priority => $priority,
    }
}
