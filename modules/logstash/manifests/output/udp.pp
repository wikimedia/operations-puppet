# = Define: logstash::output::udp
#
# output logstash messages via udp.
#
# == Parameters:
#
# - $ensure: Whether the config should exist. Default: present.
# - $priority: Configuration loading priority. Default: '90'.
# - $codec: Codec to encode output. Default 'plain'.
# - $plugin_id: Name associated with Logstash metrics
# - $host: host address to send udp log to
# - $port: port to send udp log to
# - $guard_condition: Logstash condition to require to pass events to output.
#       Default undef.
#
# == Sample usage:
#
define logstash::output::udp(
    $host,
    $port,
    $priority        = 90,
    $ensure          = present,
    $guard_condition = undef,
    String $codec    = 'plain',
    $plugin_id       = "output/udp/${title}",
) {

    logstash::conf { "output-udp-${title}":
        ensure   => $ensure,
        priority => $priority,
        content  => template('logstash/output/udp.erb'),
    }

}
