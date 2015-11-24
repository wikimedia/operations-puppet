# vim: noet
class role::memcached {
    system::role { 'role::memcached': }

    include standard
    include base::mysterious_sysctl
    include base::firewall

    $memcached_size = $::realm ? {
        'production' => 89088,
        'labs'       => 3000,
    }

    $version = os_version('debian >= jessie || ubuntu >= trusty') ? {
        true    => 'present',
        default => '1.4.15-0wmf1',
    }

    class { '::memcached':
        size          => $memcached_size,
        port          => 11211,
        version       => $version,
        extra_options => {
            '-o' => 'slab_reassign',
            '-D' => ':',
        }
    }

    # `memkeys` is a `top`-like tool for inspecting memcache key usage in real time.
    # In addition to making it available for interactive use, we configure a cronjob
    # to run once a day and log 20 seconds' worth of memcached usage stats to a CSV
    # file. That way, if there is a spike in memcached usage, we can diff the logs
    # and see which keys are suspect.

    package { 'memkeys':
        ensure => present,
        before => Cron['memkeys'],
    }

    file { '/var/log/memkeys':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Cron['memkeys'],
    }

    file { '/etc/logrotate.d/memkeys':
        source  => 'puppet:///files/memcached/memkeys.logrotate',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Cron['memkeys'],
        require => File['/var/log/memkeys'],
    }

    file { '/usr/local/sbin/memkeys-snapshot':
        source  => 'puppet:///files/memcached/memkeys-snapshot',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        before  => Cron['memkeys'],
    }

    cron { 'memkeys':
        ensure  => present,
        command => '/usr/local/sbin/memkeys-snapshot',
        user    => 'root',
        hour    => fqdn_rand(23, 'memkeys'),
        minute  => fqdn_rand(59, 'memkeys'),
    }

    ferm::service {'redis_memcached_role':
        proto    => 'tcp',
        port     => '6379',
    }

    ferm::service {'memcached_memcached_role':
        proto => 'tcp',
        port  => '11211',
    }

    rsyslog::conf { 'memkeys':
        content  => template('memcached/rsyslog.conf.erb'),
        priority => 40,
    }
}
