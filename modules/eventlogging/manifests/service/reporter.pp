# == Define: eventlogging::service::reporter
#
# EventLogging reporters reports counts of incoming events (both raw and
# valid) to StatsD. Streams are discovered automatically by walking the
# /etc/eventlogging.d/processors directory.
#
# === Parameters
#
# [*host*]
#   StatsD host. Example: 'statsd.eqiad.wmnet'.
#
# [*port*]
#   StatsD port. Defaults to 8125.
#
# [*ensure*]
#   If 'present' (the default), sets up the multiplexer. If 'absent',
#   destroys it.
#
# === Examples
#
#  eventlogging::service::reporter { 'statsd':
#    host => 'statsd.eqiad.wmnet',
#    port => 8125,
#  }
#
define eventlogging::service::reporter(
    $host,
    $port = 8125,
    $ensure = present,
) {
    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/reporters/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/reporter.erb'),
        notify  => Service['eventlogging/init', 'gmond'],
    }
}
