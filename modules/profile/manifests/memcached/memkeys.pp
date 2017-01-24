# == Class: profile::memcached::memkeys
#
# This class installs and configures memkeys, a tool to inspect memcache keys
# usage in real time.
# In addition to making it available for interactive use, it configures
# a cronjob to run once a day and log 20 seconds' worth of memcached usage stats
# to a CSV file. That way, if there is a spike in memcached usage,
# it is easier to diff the logs and see which keys are suspect.
#
class profile::memcached::memkeys {

    package { 'memkeys':
        ensure => present,
        before => Cron['memkeys'],    }

    file { '/var/log/memkeys':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Cron['memkeys'],
    }

    file { '/etc/logrotate.d/memkeys':
        source  => 'puppet:///modules/memcached/memkeys.logrotate',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Cron['memkeys'],
        require => File['/var/log/memkeys'],
    }

    file { '/usr/local/sbin/memkeys-snapshot':
        source => 'puppet:///modules/memcached/memkeys-snapshot',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Cron['memkeys'],
    }

    cron { 'memkeys':
        ensure  => present,
        command => '/usr/local/sbin/memkeys-snapshot',
        user    => 'root',
        hour    => fqdn_rand(23, 'memkeys'),
        minute  => fqdn_rand(59, 'memkeys'),
    }

    rsyslog::conf { 'memkeys':
        content  => template('role/memcached/rsyslog.conf.erb'),
        priority => 40,
    }
}
