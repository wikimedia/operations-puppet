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

    # /var/log/local serves a destination for any custom local rsyslog log
    # files. Log files are rotated automatically. This allows logrotate to be
    # invoked as the rotation command an rsyslog outchannel. For example:
    #
    #   $outchannel apache2,/var/log/apache2.log,100000000,
    #     /usr/sbin/logrotate -f /etc/logrotate.d/rsyslog-local
    #
    # See rsyslog.conf(5) for details.

    file { '/var/log/local':
        ensure  => directory,
        owner   => 'syslog',
        group   => 'adm',
        mode    => '0755',
        require => Package['rsyslog'],
    }

    file { '/etc/logrotate.d/rsyslog-local':
        source  => 'puppet:///modules/rsyslog/rsyslog-local.logrotate',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/var/log/rsyslog'],
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
