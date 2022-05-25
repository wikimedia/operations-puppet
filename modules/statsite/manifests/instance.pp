# SPDX-License-Identifier: Apache-2.0
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
    Wmflib::Ensure $ensure            = present,
    Stdlib::Port   $port              = 8125,
    Stdlib::Host   $graphite_host     = 'localhost',
    Stdlib::Port   $graphite_port     = 2003,
    String         $input_counter     = "statsd.${::hostname}.received",
    Integer        $extended_counters = 1,
) {
    $python = $::lsbdistcodename ? {
        default => 'python3',
        stretch => 'python',
        buster  => 'python',
    }

    $stream_cmd = "${python} /usr/lib/statsite/sinks/graphite.py ${graphite_host} ${graphite_port} \"\""

    file { "/etc/statsite/${port}.ini":
        ensure  => $ensure,
        content => template('statsite/statsite.ini.erb'),
        require => Package['statsite'],
        notify  => Service["statsite@${port}"],
    }

    case $ensure {
      'absent': {
        $service_enable = false
      }
      default: {
        $service_enable = true
      }
    }

    service { "statsite@${port}":
        ensure   => stdlib::ensure($ensure, 'service'),
        provider => 'systemd',
        enable   => $service_enable,
        require  => File['/lib/systemd/system/statsite@.service'],
    }
}
