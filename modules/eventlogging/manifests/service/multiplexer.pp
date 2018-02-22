# == Define: eventlogging::service::multiplexer
#
# An EventLogging multiplexer forwards multiple ZeroMQ inputs into a
# single ZeroMQ publisher.
#
# === Parameters
#
# [*inputs*]
#   An array of URIs for ZeroMQ publishers that should be selected as
#   input. Example: ['tcp://127.0.0.1:8521', 'tcp://127.0.0.1:8522'].
#
# [*output*]
#   Bind the multiplexing publisher to this URI.
#   Example: 'tcp://*:8600'.
#
# [*sid*]
#   Socket ID multiplexer should use to identify itself when subscribing
#   to input streams. Defaults to the resource title.
#
# [*ensure*]
#   If 'present' (the default), sets up the multiplexer. If 'absent',
#   destroys it.
#
# === Examples
#
#  eventlogging::service::multiplexer { 'all_events':
#    inputs => [ 'tcp://127.0.0.1:8521', 'tcp://127.0.0.1:8522' ],
#    output => 'tcp://*:8600',
#  }
#
define eventlogging::service::multiplexer(
    $inputs,
    $output,
    $sid     = $title,
    $ensure  = present,
) {
    Class['eventlogging::server'] -> Eventlogging::Service::Multiplexer[$title]

    # eventlogging will run out of the path configured in the
    # eventlogging::server class.
    $eventlogging_path = $eventlogging::server::eventlogging_path
    $eventlogging_log_dir = $eventlogging::server::log_dir
    $basename = regsubst($title, '\W', '-', 'G')
    $config_file = "/etc/eventlogging.d/multiplexers/${basename}"
    $service_name = "eventlogging-multiplexer@${basename}"
    $_log_file = "${eventlogging_log_dir}/${service_name}.log"

    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/multiplexer.erb'),
    }

    if os_version('debian >= stretch') {
        rsyslog::conf { $service_name:
            content  => template('eventlogging/rsyslog.conf.erb'),
            priority => 80,
        }
        systemd::service { $service_name:
            ensure  => present,
            content => systemd_template('eventlogging-multiplexer@'),
            restart => true,
            require => File[$config_file],
        }
    }
}
