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
#   Write logs to this directory
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

    # it doesn't seem possible to recursively create a directory tree
    # http://www.puppetcookbook.com/posts/creating-a-directory-tree.html
    exec { 'rsyslog_receiver_log_dir':
        command => "/bin/mkdir -p ${log_directory}",
        creates => $log_directory,
    }

    file { $log_directory:
        ensure  => present,
        owner   => 'syslog',
        group   => 'root',
        mode    => '0755',
        require => Exec['rsyslog_receiver_log_dir'],
    }

    file { $archive_directory:
        ensure  => directory,
        owner   => 'syslog',
        group   => 'root',
        mode    => '0755',
        require => Exec['rsyslog_receiver_log_dir'],
    }
}
