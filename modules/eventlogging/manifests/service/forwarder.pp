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
#       'kafka://?brokers=localhost:9092&topic=eventlogging',
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
    include ::eventlogging

    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/forwarders/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/forwarder.erb'),
        notify  => Service['eventlogging/init'],
    }
}
