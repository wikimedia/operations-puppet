# SPDX-License-Identifier: Apache-2.0
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
    $tcp_port           = 6514,
    $log_retention_days = 90,
    $log_directory      = '/srv/syslog',
    $archive_directory  = '/srv/syslog/archive',
) {
    if debian::codename::eq('buster') {
        apt::package_from_component { 'rsyslog_receiver':
            component => 'component/rsyslog',
            packages  => ['rsyslog-gnutls', 'rsyslog-kafka', 'rsyslog'],
            before    => Class['rsyslog'],
        }
    } else {
        ensure_packages('rsyslog-gnutls')
    }

    if ($log_directory == $archive_directory) {
        fail("rsyslog log and archive are the same: ${log_directory}")
    }

    # SSL configuration
    # TODO: consider using profile::pki::get_cert
    puppet::expose_agent_certs { '/etc/rsyslog-receiver':
        provide_private => true,
    }

    systemd::unit { 'rsyslog':
        ensure   => present,
        override => true,
        content  => template('rsyslog/initscripts/rsyslog_receiver.systemd_override.erb'),
    }

    file { '/etc/rsyslog-receiver':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
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

    # Plumb rsync pull from eqiad by codfw centrallog hosts, useful for re-syncing logs
    # inactive (ensure => absent, auto_sync => false)  but kept here to be
    # quickly enabled when needed.
    rsync::quickdatacopy { 'centrallog':
        ensure              => absent,
        source_host         => 'centrallog2001.codfw.wmnet',
        dest_host           => 'centrallog2002.codfw.wmnet',
        auto_sync           => false,
        module_path         => '/srv',
        server_uses_stunnel => true,
    }

}
