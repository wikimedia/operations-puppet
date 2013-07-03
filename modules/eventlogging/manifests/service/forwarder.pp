# == Define: eventlogging::service::forwarder
#
# An EventLogging forwarder listens for data on an inbound UDP port and
# publishes that data on a ZeroMQ PUB socket that is bound to the same
# port number, TCP.
#
# === Parameters
#
# [*port*]
#   Port which should be forwarded. Defaults to the resource title.
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
#  eventlogging::service::forwarder { '8600': ]
#
define eventlogging::service::forwarder(
    $port   = $title,
    $count  = false,
    $ensure = present,
) {
    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/forwarders/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/forwarder.erb'),
        notify  => Service['eventlogging/init'],
    }
}
