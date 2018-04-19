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
# [*ensure*]
#   Whether mtail should be running or stopped.

class mtail (
  $logs = ['/var/log/syslog'],
  $port = '3903',
  $ensure = 'running',
  $group = 'root',
) {
    validate_array($logs)
    validate_re($port, '^[0-9]+$')
    validate_re($ensure, '^(running|stopped)$')

    if os_version('debian == stretch') {
        apt::pin { 'mtail':
            pin      => 'release a=stretch-backports',
            package  => 'mtail',
            priority => '1001',
            before   => Package['mtail'],
        }
    }

    # Not using require_package so apt::pin may be
    # applied before attempting to install mtail.
    package { 'mtail':
        ensure => present,
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
        ensure         => present,
        content        => systemd_template('mtail'),
        restart        => true,
        service_params => {
            ensure => $ensure,
        },
    }
}
