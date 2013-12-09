# = Class: logstash::input::udp2log
#
# Configure logstash to collect input as a udp2log relay listener.
#
# == Parameters:
# - $port: port to listen for udp2log input on
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   class { 'logstash::input::udp2log':
#       udp2log_port => '8324',
#   }
#
class logstash::input::udp2log(
    $port     = '8324',
    $priority = '10',
    $ensure   = present,
) {
    require logstash

    @logstash::conf{ 'udp2log-input':
        content  => template('logstash/input/udp2log.erb'),
        priority => $priority,
        ensure   => $ensure,
    }
}
# vim:sw=4 ts=4 sts=4 et:
