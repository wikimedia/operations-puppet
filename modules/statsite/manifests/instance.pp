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
    $graphite_host     = hiera('statsite::instance::graphite_host', 'localhost'),
    $graphite_port     = hiera('statsite::instance::graphite_port', 2003),
    $input_counter     = "statsd.${::hostname}.received",
    $extended_counters = hiera('statsite::instance::extended_counters', 1),
) {
    $stream_cmd = "python /usr/lib/statsite/sinks/graphite.py ${graphite_host} ${graphite_port} \"\""

    if $::initsystem == 'upstart' {
        file { "/etc/statsite/${port}.ini":
            content => template('statsite/statsite.ini.erb'),
            require => Package['statsite'],
            notify  => Service['statsite'],
        }
    }

    if $::initsystem == 'systemd' {
        $instance_service_path = "/lib/systemd/system/statsite@${port}.service"
        $template_service_path = '/lib/systemd/system/statsite@.service'

        file { $instance_service_path:
            ensure  => 'link',
            target  => $template_service_path,
            require => File[$template_service_path],
        }

        file { "/etc/statsite/${port}.ini":
            content => template('statsite/statsite.ini.erb'),
            require => Package['statsite'],
            notify  => Service["statsite@${port}"],
        }

        service { "statsite@${port}":
            ensure   => 'running',
            provider => 'systemd',
            enable   => true,
            require  => File[$instance_service_path],
        }
    }
}
