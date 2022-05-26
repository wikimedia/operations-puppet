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
}
