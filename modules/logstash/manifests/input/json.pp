# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::json
#
# Configure logstash to collect input as a json listener.
#
# == Parameters:
# - $ensure: Whether the config should exist. Default present.
# - $port: port to listen for json input on. Default 12202.
# - $priority: Configuration loading priority. Default undef.
#
# == Sample usage:
#
#   logstash::input::json {
#       port => 12202,
#   }
#
define logstash::input::json(
    $ensure   = present,
    $port     = 12202,
    $priority = undef,
) {
    logstash::conf { "input_json_${title}":
        ensure   => $ensure,
        content  => template('logstash/input/json.erb'),
        priority => $priority,
    }
}
