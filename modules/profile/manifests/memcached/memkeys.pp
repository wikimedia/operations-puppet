# == Class: profile::memcached::memkeys
#
# This class installs and configures memkeys, a tool to inspect memcache keys
# usage in real time.
# In addition to making it available for interactive use, it configures a systemd
# timer job to run once a day and log 20 seconds' worth of memcached usage stats
# to a CSV file. That way, if there is a spike in memcached usage,
# it is easier to diff the logs and see which keys are suspect.
#
class profile::memcached::memkeys {

    ensure_packages(['memkeys'])

    file { '/var/log/memkeys':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/logrotate.d/memkeys':
        source  => 'puppet:///modules/memcached/memkeys.logrotate',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/var/log/memkeys'],
    }

    file { '/usr/local/sbin/memkeys-snapshot':
        source => 'puppet:///modules/memcached/memkeys-snapshot',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $hour = fqdn_rand(24, 'hour-memkeys')
    $minute = fqdn_rand(60, 'minute-memkeys')

    systemd::timer::job { 'memkeys-snapshot':
        ensure      => present,
        description => 'Regular jobs to log memcached usage stats',
        user        => 'root',
        command     => '/usr/local/sbin/memkeys-snapshot',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* ${hour}:${minute}:00"},
    }

    rsyslog::conf { 'memkeys':
        content  => template('role/memcached/rsyslog.conf.erb'),
        priority => 40,
    }
}
