# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::log4j
#
# Configure logstash to collect input from a Java application via log4j
#
# == Parameters:
# - $ensure: Whether the config should exist.
# - $mode: Whether to list for incoming connections ('server') or connect to a
#          remote host ('client')
# - $host: Log4j host to contact. Default 0.0.0.0
# - $port: Log4j socket port. Default 4560
# - $priority: Configuration loading priority. Default '10'.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::inputs::log4j { 'log4j':
#       mode => 'client',
#       host => '127.0.0.1',
#   }
#
define logstash::input::log4j(
    $ensure     = present,
    $mode       = 'server',
    $host       = '0.0.0.0',
    $port       = 4560,
    $priority   = 10,
    $plugin_id  = "input/log4j/${port}",
    $tags       = undef,
) {
    logstash::conf { "input-log4j-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/log4j.erb'),
        priority => $priority,
    }
}
