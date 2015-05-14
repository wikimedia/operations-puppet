# == Define: eventlogging::service::forwarder
#
# An EventLogging forwarder listens for data on an inbound UDP port and
# publishes that data on a ZeroMQ PUB socket that is bound to the same
# port number, TCP.
#
# === Parameters
#
# [*input*]
#   Input URI from which events should be forwarded.
#   Defaults to  udp://0.0.0.0:$title (make sure $title is the port if you don't set this.)
#
# [*outputs*]
#   An array of URIs for various publishers that should be selected as output.
#   Example: ['tcp://127.0.0.1:8521', 'kafka://?brokers=localhost:9092&topic=eventlogging'].
#   Defaults to ['tcp://*:$title'] (make sure $title is the port if you don't set this.)
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
#  eventlogging::service::forwarder { '8600': }
#  eventlogging::service::forwarder { 'kafka-zmq_8601':
#    input => 'kafka://?brokers=localhost:9092&topic=eventlogging',
#    port  => '8601',
#  }
#
define eventlogging::service::forwarder(
    $input    = "udp://0.0.0.0:${title}",
    $outputs  = ["tcp://*:$title"],
    $count    = false,
    $ensure   = present,
) {
    include ::eventlogging

    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/forwarders/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/forwarder.erb'),
        notify  => Service['eventlogging/init'],
    }
}
