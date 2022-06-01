# SPDX-License-Identifier: Apache-2.0
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
# [*socket_receive_bufsize*]
#   SO_RCVBUF size. Defaults to 6M.  (Kernel will ultimately double this value per socket(7))
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
    Stdlib::Port        $server_port,
    Array[Stdlib::Port] $backend_ports,
    Wmflib::Ensure      $ensure                 = present,
    Integer             $threads                  = 4,
    Integer             $socket_receive_bufsize = 6291456,
) {

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
        ensure    => stdlib::ensure($ensure, 'service'),
        enable    => $ensure == 'present',
        provider  => $::initsystem,
        subscribe => [
            Package['statsd-proxy'],
        ],
    }
}
