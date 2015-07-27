# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::gelf
#
# Configure logstash to collect input as a gelf (graylog) listener.
#
# == Parameters:
# - $port: port to listen for gelf input on
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   logstash::input::gelf {
#       port => 12201,
#   }
#
define logstash::input::gelf(
    $ensure   = present,
    $port     = 12201,
    $priority = 10,
) {
    logstash::conf { "input-gelf-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/gelf.erb'),
        priority => $priority,
    }

    ferm::service { "logstash_gelf_${title}":
        proto  => 'udp',
        port   => $port,
        srange => '$INTERNAL',
    }
}
