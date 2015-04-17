# == Class: rsyslog
#
# rsyslogd is a full-featured kernel logging daemon. It is the default
# syslogd implementation on Debian systems.
#
class rsyslog {
    package { 'rsyslog':
        ensure => present,
    }

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
}
