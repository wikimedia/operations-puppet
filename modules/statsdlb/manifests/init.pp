# == Class: statsdlb
#
# statsdlb is a StatsD-compatible proxy which routes metrics to multiple local
# UDP ports. It chooses the backend port for each metric by hashing the metric
# name, to ensure aggregation works properly. Its purpose is to allow scaling
# StatsD implementations which cannot exploit multiple CPU cores.
#
# === Parameters
#
# [*server_port*]
#   UDP port to listen on. Example: 9001.
#
# [*backend_ports*]
#   Array of local UDP ports to which incoming metrics should be routed.
#   Example: [ 9002, 9003, 9004 ].
#
# === Examples
#
#  # Listen on UDP port 9001 and route to ports 9002-9004:
#  class { 'statsdlb':
#    server_port   => 9001,
#    backend_ports => [ 9002, 9003, 9004 ],
#  }
#
class statsdlb(
    $ensure = present,
    $server_port,
    $backend_ports,
) {
    validate_ensure($ensure)
    validate_array($backend_ports)
    validate_re($backend_ports, '^\d+(\s\d+)*$', '$backend_ports must be an array of port numbers')
    validate_re($server_port, '^\d+$', '$server_port must be a port number')

    package { 'statsdlb':
        ensure => $ensure,
    }

    file { '/etc/default/statsdlb':
        ensure  => $ensure,
        content => sprintf("DAEMON_ARGS=\"%s %s\"\n", $server_port, join($backend_ports, ' ')),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'statsdlb':
        ensure    => ensure_service($ensure),
        enable    => $ensure == 'present',
        provider  => $::initsystem,
        subscribe => [
            Package['statsdlb'],
            File['/etc/default/statsdlb'],
        ],
    }
}
