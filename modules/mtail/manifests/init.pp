# SPDX-License-Identifier: Apache-2.0
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
    ensure_packages('mtail')

    file { '/etc/default/mtail':
        ensure  => present,
        mode    => '0444',
        content => debian::codename::ge('bookworm') ? {
            true  => template('mtail/default-bookworm.erb'),
            false => template('mtail/default.erb'),
        },
        notify  => Service['mtail'],
    }

    systemd::service { 'mtail':
        ensure   => $service_ensure,
        content  => debian::codename::ge('bookworm') ? {
            true  => init_template('mtail', 'systemd_override_bookworm'),
            false => init_template('mtail', 'systemd_override'),
        },
        override => true,
        restart  => true,
    }
}
