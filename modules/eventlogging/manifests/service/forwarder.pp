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
# [*port*]
#   Port which should be forwarded to. Defaults to the resource title.
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
    $input  = "udp://0.0.0.0:${title}",
    $port   = $title,
    $count  = false,
    $ensure = present,
) {
    include ::eventlogging

    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/forwarders/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/forwarder.erb'),
        notify  => Service['eventlogging/init'],
    }
}
