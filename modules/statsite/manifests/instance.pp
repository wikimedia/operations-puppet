# == Define: statsite
#
# Configure an instance of statsite
#
# === Parameters
#
# [*port*]
#   Port to listen for messages on over UDP.
#
# [*graphite_host*]
#   Send metrics to graphite on this host
#
# [*graphite_port*]
#   Send metrics to graphite on this port
#
# [*input_counter*]
#   Use this metric to report self-statistics
#
# [*extended_counters*]
#   Export additional metrics for counters

define statsite::instance(
    $port              = 8125,
    $graphite_host     = hiera('statsite::instance::graphite_host','graphite-in.eqiad.wmnet'),
    $graphite_port     = hiera('statsite::instance::graphite_port', 2003),
    $input_counter     = "statsd.${::hostname}.received",
    $extended_counters = hiera('statsite::instance::extended_counters', 0),
) {
    $stream_cmd = "python /usr/lib/statsite/sinks/graphite.py $graphite_host $graphite_port \"\""

    if os_version('ubuntu >= precise') {
        file { "/etc/statsite/$port.ini":
            content => template('statsite/statsite.ini.erb'),
            require => Package['statsite'],
            notify  => Service['statsite'],
        }
    }

    if os_version('debian >= jessie') {
        file { "/etc/statsite.ini":
            content => template('statsite/statsite.ini.erb'),
            require => Package['statsite'],
            notify  => Service['statsite'],
        }
    }
}
