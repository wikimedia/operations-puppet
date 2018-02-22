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
    Class['eventlogging::server'] -> Eventlogging::Service::Reporter[$title]

    $basename = regsubst($title, '\W', '-', 'G')
    $config_file = "/etc/eventlogging.d/reporters/${basename}"

    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/reporter.erb'),
    }

    if os_version('debian >= stretch') {
        systemd::service { "eventlogging-reporter@${basename}":
            ensure  => present,
            content => systemd_template('eventlogging-reporter@'),
            restart => true,
            require => File[$config_file],
        }
    }
}
