# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::syslog
#
# Configure logstash to collect input as a syslog listener.
#
# == Parameters:
# - $ensure: Whether the config should exist.
# - $port: port to listen for syslog input on
# - $priority: Configuration loading priority. Default '10'.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::input::syslog { 'syslog':
#       port => 514,
#    }
#
define logstash::input::syslog(
    $ensure    = present,
    $port      = 514,
    $priority  = 10,
    $plugin_id = "input/syslog/${port}",
    $tags      = undef,
) {
    logstash::conf { "input-syslog-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/syslog.erb'),
        priority => $priority,
    }
}
