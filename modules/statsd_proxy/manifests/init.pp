# == Class: statsd_proxy
#
# statsd-proxy is a StatsD-compatible proxy which routes metrics to multiple
# local UDP ports. It consistently hashes metrics uses Ketama and is built for
# high-performance.
#
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
# [*threads*]
#   Number of threads to spawn. Defaults to 4.
#
# === Examples
#
#  # Listen on UDP port 9001 and route to ports 9002-9004:
#  class { 'statsd_proxy':
#    server_port   => 9001,
#    backend_ports => [ 9002, 9003, 9004 ],
#  }
#
class statsd_proxy(
    $server_port,
    $backend_ports,
    $ensure = present,
    $threads = 4,
) {
    validate_ensure($ensure)
    validate_array($backend_ports)
    validate_numeric($backend_ports)
    validate_numeric($server_port)

    package { 'statsd-proxy':
        ensure => $ensure,
    }

    file { '/etc/statsd-proxy.cfg':
        ensure  => $ensure,
        content => template('statsd_proxy/statsd-proxy.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'statsd-proxy':
        ensure    => ensure_service($ensure),
        enable    => $ensure == 'present',
        provider  => $::initsystem,
        subscribe => [
            Package['statsd-proxy'],
        ],
    }
}
