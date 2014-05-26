# == Class: rsyslog
#
# rsyslogd is a full-featured kernel logging daemon. It's the default
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
        require => Package['rsyslog'],
        notify  => Service['rsyslog'],
    }

    service { 'rsyslog':
        ensure    => running,
        provider  => 'upstart',
        require   => Package['rsyslog'],
    }

    rsyslog::conf { 'default':
        source   => '/usr/share/rsyslog/50-default.conf',
        priority => 50,
        require  => Package['rsyslog'],
    }
}
