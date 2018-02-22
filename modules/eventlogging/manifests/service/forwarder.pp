# == Define: eventlogging::service::forwarder
#
# An EventLogging forwarder listens for data on an inbound UDP port and
# publishes that data to all of the outputs in the outputs parameter.
#
# === Parameters
#
# [*input*]
#   Input URI from which events should be forwarded.
#   Defaults to  udp://0.0.0.0:$title (make sure $title is the port if you don't set this.)
#
# [*outputs*]
#   An array of URIs to output to.  Defaults to an empty array.  Example: [
#       'tcp://eventlog1001.eqiad.wmnet:8421',
#       'kafka:///localhost:9092?topic=eventlogging-server-side',
#   ]
#
# [*count*]
#   If true, prepend an autoincrementing ID to each message that is
#   forwarded. False by default.
#
# [*ensure*]
#   If 'present' (the default), enable the service; if 'absent', disable
#   and remove it.
#
# === Examples
#
#  eventlogging::service::forwarder { 'kafka-zmq_8601':
#    input      => 'kafka://?brokers=localhost:9092&topic=eventlogging',
#    outputs    => [
#       'tcp://eventlog1001.eqiad.wmnet:8421',
#       'kafka://?brokers=localhost:9092&topic=eventlogging',
#    ],
#  }
#
define eventlogging::service::forwarder(
    $input      = "udp://0.0.0.0:${title}",
    $outputs    = [],
    $count      = false,
    $ensure     = present,
) {
    Class['eventlogging::server'] -> Eventlogging::Service::Forwarder[$title]

    # eventlogging will run out of the path configured in the
    # eventlogging::server class.
    $eventlogging_path = $eventlogging::server::eventlogging_path
    $eventlogging_log_dir = $eventlogging::server::log_dir
    $basename = regsubst($title, '\W', '-', 'G')
    $config_file = "/etc/eventlogging.d/forwarders/${basename}"
    $service_name = "eventlogging-forwarder@${basename}"
    $_log_file = "${eventlogging_log_dir}/${service_name}.log"

    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/forwarder.erb'),
    }

    if os_version('debian >= stretch') {
        rsyslog::conf { $service_name:
            content  => template('eventlogging/rsyslog.conf.erb'),
            priority => 80,
        }
        systemd::service { $service_name:
            ensure  => present,
            content => systemd_template('eventlogging-consumer@'),
            restart => true,
            require => File[$config_file],
        }
    }
}
