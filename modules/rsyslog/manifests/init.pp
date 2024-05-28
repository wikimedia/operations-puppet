# SPDX-License-Identifier: Apache-2.0
# == Class: rsyslog
#
# rsyslogd is a full-featured kernel logging daemon. It is the default
# syslogd implementation on Debian systems.
#
class rsyslog {
    ensure_packages('rsyslog')

    file { '/etc/rsyslog.d':
        ensure  => directory,
        source  => 'puppet:///modules/rsyslog/rsyslog.d-empty',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
        ignore  => '50-default.conf',
        require => Package['rsyslog'],
        notify  => Service['rsyslog'],
    }

    service { 'rsyslog':
        ensure  => running,
        require => Package['rsyslog'],
    }

    file { '/etc/rsyslog.d/00-abort-unclean-config.conf':
        ensure => absent,
        notify => Service['rsyslog'],
    }

    profile::auto_restarts::service { 'rsyslog': }

    $rsyslog_global_conf = '/etc/rsyslog.d/00-global.conf'
    concat { $rsyslog_global_conf:
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        order  => 'alpha',
        notify => Service['rsyslog'],
    }
    concat::fragment { "${rsyslog_global_conf}-header":
        target  => $rsyslog_global_conf,
        order   => '000',
        content => "global(\n",
    }
    concat::fragment { "${rsyslog_global_conf}-trailer":
        target  => $rsyslog_global_conf,
        order   => 'zzz',
        content => ")\n",
    }

    # Include slashes in program names, as used in programs like
    # 'postfix/smtpd', rather than stopping at the slash.
    rsyslog::global_entry('parser.permitSlashInProgramName', 'on')
}
