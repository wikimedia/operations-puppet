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

    # By default, rsyslogd startup is successful (exit status 0) even in the
    # face of invalid configurations, for example due to syntax errors in one
    # of the /etc/rsyslog.d/ files. Set the AbortOnUncleanConfig to 'on' to
    # fail startup in such cases instead.
    # https://phabricator.wikimedia.org/T290870
    # https://www.rsyslog.com/doc/v8-stable/rainerscript/global.html
    rsyslog::conf { 'abort_unclean_config':
        ensure   => 'present',
        content  => '$AbortOnUncleanConfig on',
        priority => 00,
    }

    base::service_auto_restart { 'rsyslog': }
}
