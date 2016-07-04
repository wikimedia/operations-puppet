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
        values => { 'kernel/mm/transparent_hugepage/enabled' => 'never' }
    }

    # Background save may fail under low memory condition unless
    # vm.overcommit_memory is 1.
    sysctl::parameters { 'vm.overcommit_memory':
        values => { 'vm.overcommit_memory' => 1 },
    }

    if os_version('debian >= jessie') {
        file_line { 'enable_latency_monitor':
            line  => 'latency-monitor-threshold 100',
            match => '^latency-monitor-threshold',
            path  => '/etc/redis/redis.conf',
        }
    }

    # ensure that /var/run/redis is created at boot
    if os_version('debian >= jessie') {
        file { '/etc/tmpfiles.d/redis-startup.conf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => 'd /var/run/redis 0755 redis redis',
        }
    } else {
        base::service_unit { 'redis-startup':
            ensure          => present,
            template_name   => 'redis-startup',
            upstart         => true,
            declare_service => false,
        }
    }
}
