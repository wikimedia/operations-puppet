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
    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/multiplexers/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/multiplexer.erb'),
        notify  => Service['eventlogging/init', 'gmond'],
    }
}
