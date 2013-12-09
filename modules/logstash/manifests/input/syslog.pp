# = Class: logstash::input::syslog
#
# Configure logstash to collect input as a syslog listener.
#
# == Parameters:
# - $port: port to listen for syslog input on
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   class { 'logstash::input::syslog':
#       port => '514',
#   }
#
class logstash::input::syslog(
    $port     = '514',
    $priority = '10',
    $ensure   = present,
) {
    require logstash

    @logstash::conf{ 'syslog-input':
        content  => template('logstash/input/syslog.erb'),
        priority => $priority,
        ensure   => $ensure,
    }
}
# vim:sw=4 ts=4 sts=4 et:
