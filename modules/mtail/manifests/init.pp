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

    require_package('mtail')

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
