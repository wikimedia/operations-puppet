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
    $graphite_host     = 'localhost',
    $graphite_port     = 2003,
    $input_counter     = "statsd.${::hostname}.received",
    $extended_counters = 0,
) {
    $stream_cmd = "python /usr/lib/statsite/sinks/graphite.py ${graphite_host} ${graphite_port}"

    file { "/etc/statsite/${port}.ini":
        content => template('statsite/statsite.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['statsite'],
        notify  => Service['statsite'],
    }
}
