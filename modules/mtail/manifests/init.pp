# == Class: mtail
#
# Setup mtail to scan $logs and report metrics based on programs in /etc/mtail.
#
# === Parameters
#
# [*logs*]
#   Array of log files to follow
#
# [*port*]
#   TCP port to listen to for Prometheus-style metrics
#
# [*service_ensure*]
#   Whether mtail.service should be present or absent.
#
# [*from_component*]
#   Installs mtail from component

class mtail (
    Array[Stdlib::Unixpath] $logs   = ['/var/log/syslog'],
    Stdlib::Port $port              = 3903,
    Wmflib::Ensure $service_ensure  = 'present',
    String $group                   = 'root',
    Boolean $from_component         = false,
    String $additional_args         = ''
) {
    if ( $from_component ) {
        apt::package_from_component { 'mtail':
            component => 'component/mtail'
        }
    } else {
        apt::pin { 'mtail':
            pin      => 'version 3.0.0~rc35-3+wmf3',
            package  => 'mtail',
            priority => 1001,
            before   => Package['mtail'],
        }
        # Not using require_package so apt::pin may be
        # applied before attempting to install mtail.
        package { 'mtail':
            ensure => '3.0.0~rc35-3+wmf3',
        }
    }

    file { '/etc/default/mtail':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mtail/default.erb'),
        notify  => Service['mtail'],
    }

    systemd::service { 'mtail':
        ensure   => $service_ensure,
        content  => init_template('mtail', 'systemd_override'),
        override => true,
        restart  => true,
    }
}
