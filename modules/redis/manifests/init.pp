# == Class: redis
#
# Redis is an in-memory data store with support for rich data structures,
# scripting, transactions, persistence, and high availability.
#
class redis {
    require_package('redis-server')

    file { [ '/srv/redis', '/var/lib/redis', '/var/log/redis' ]:
        ensure => directory,
        owner  => 'redis',
        group  => 'redis',
        mode   => '0755',
    }

    # Disable the default, system-global redis service,
    # because it's incompatible with a multi-instance setup.
    service { 'redis-server':
        ensure    => stopped,
        enable    => false,
        subscribe => Package['redis-server'],
    }

    # Disabling transparent hugepages is strongly recommended
    # in http://redis.io/topics/latency.
    sysfs::parameters { 'disable_transparent_hugepages':
        values => { 'kernel/mm/transparent_hugepage/enabled' => 'never' },
    }

    # Background save may fail under low memory condition unless
    # vm.overcommit_memory is 1.
    sysctl::parameters { 'vm.overcommit_memory':
        values => { 'vm.overcommit_memory' => 1 },
    }

    # Manage the redis.conf file again as we need it
    # to be the simplest lowest-common denominator
    file { '/etc/redis/redis-common.conf':
        ensure => present,
        source => 'puppet:///modules/redis/redis-common.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        before => File['/etc/redis/redis.conf'],
    }

    # Distro-specific common directives go here
    file { '/etc/redis/redis.conf':
        ensure => present,
        source => "puppet:///modules/redis/redis-${::lsbdistcodename}.conf",
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # ensure that /var/run/redis is created at boot
    file { '/etc/tmpfiles.d/redis-startup.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => 'd /var/run/redis 0755 redis redis',
    }
}
