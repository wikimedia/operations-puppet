# == Class: rsyslog::receiver
#
# Setup the rsyslog daemon as a receiver for remote logs.
#
# === Parameters
#
# [*udp_port*]
#   Listen for UDP syslog on this port
#
# [*log_retention_days*]
#   How long to keep logs in $archive_directory for
#
# [*log_directory*]
#   Write logs to this directory, parent directory must already
#   exist.
#
# [*archive_directory*]
#   Archive logs into this directory, it is an error to set this equal to
#   $log_directory and vice versa.

class rsyslog::receiver (
    $udp_port           = 514,
    $log_retention_days = 30,
    $log_directory      = '/srv/syslog',
    $archive_directory  = '/srv/syslog/archive',
) {

    if ($log_directory == $archive_directory) {
        fail("rsyslog log and archive are the same: $log_directory")
    }

    rsyslog::conf { 'receiver':
        content  => template("${module_name}/receiver.erb.conf"),
        priority => 10,
    }

    file { '/etc/logrotate.d/rsyslog_receiver':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/receiver_logrotate.erb.conf"),
    }

    # disable DNS lookup for remote messages
    file { '/etc/default/rsyslog':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => 'RSYSLOGD_OPTIONS="-x"',
        notify  => Service['rsyslog'],
    }

    file { $log_directory:
        ensure  => directory,
        owner   => 'syslog',
        group   => 'root',
        mode    => '0755',
    }

    file { $archive_directory:
        ensure  => directory,
        owner   => 'syslog',
        group   => 'root',
        mode    => '0755',
    }
}
