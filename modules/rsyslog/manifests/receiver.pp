# == Class: rsyslog::receiver
#
# Setup the rsyslog daemon as a receiver for remote logs.
#
# === Parameters
#
# [*udp_port*]
#   Listen for UDP syslog on this port
#
# [*tcp_port*]
#   Listen for TCP syslog on this port (TLS only)
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
    $tcp_port           = 10514,
    $log_retention_days = 90,
    $log_directory      = '/srv/syslog',
    $archive_directory  = '/srv/syslog/archive',
) {
    require_package('rsyslog-gnutls')

    if ($log_directory == $archive_directory) {
        fail("rsyslog log and archive are the same: ${log_directory}")
    }

    # SSL configuration
    ::base::expose_puppet_certs { '/etc/rsyslog-receiver/':
        provide_private => true,
    }

    file { '/etc/rsyslog-receiver':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        before => Base::Expose_Puppet_Certs['/etc/rsyslog-receiver'],
    }

    file { '/etc/rsyslog-receiver/certs/ca.pem':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => '/var/lib/puppet/ssl/certs/ca.pem',
        require => Base::Expose_Puppet_Certs['/etc/rsyslog-receiver'],
    }

    rsyslog::conf { 'receiver':
        content  => template("${module_name}/receiver.erb.conf"),
        priority => 10,
    }

    logrotate::conf { 'rsyslog_receiver':
        ensure  => present,
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
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $archive_directory:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
