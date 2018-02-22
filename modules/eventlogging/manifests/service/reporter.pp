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

    # eventlogging will run out of the path configured in the
    # eventlogging::server class.
    $eventlogging_path = $eventlogging::server::eventlogging_path
    $eventlogging_log_dir = $eventlogging::server::log_dir
    $basename = regsubst($title, '\W', '-', 'G')
    $config_file = "/etc/eventlogging.d/reporters/${basename}"
    $service_name = "eventlogging-reporter@${basename}"
    $_log_file = "${eventlogging_log_dir}/${service_name}.log"

    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/reporter.erb'),
    }

    if os_version('debian >= stretch') {
        rsyslog::conf { $service_name:
            content  => template('eventlogging/rsyslog.conf.erb'),
            priority => 80,
        }
        systemd::service { $service_name:
            ensure  => present,
            content => systemd_template('eventlogging-reporter@'),
            restart => true,
            require => File[$config_file],
        }
    }
}
