# == Class: redis
#
# Redis is an in-memory data store with support for rich data structures,
# scripting, transactions, persistence, and high availability.
#
class redis {
    require_package('redis-server')

    file { '/srv/redis':
        owner => 'redis',
        group => 'redis',
        mode  => '0755',
    }

    # Hosts that use systemd are able to manage multiple redis
    # instances. Individual instances are managed by interpolating
    # the instance name in a systemd unit template file.
    # See <http://0pointer.de/blog/projects/instances.html>.
    if $::initsystem == 'systemd' {
        file { '/lib/systemd/system/redis-instance@.service':
            source => 'puppet:///modules/redis/redis-instance@.service',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }
    }
}
