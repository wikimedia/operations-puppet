class role::jobqueue_redis {
    include ::standard
    include ::passwords::redis

    system::role { 'role::jobqueue_redis': }

    $password = $passwords::redis::main_password
    $slaveof = hiera('jobqueue_redis_slaveof', undef)
    $instances = apply_format("localhost:%s/${password}", range(6378, 6382))

    # Aggregator backend
    mediawiki::jobqueue_redis { 6378: slaveof => $slaveof }

    # Queues
    mediawiki::jobqueue_redis { 6379: slaveof => $slaveof }
    mediawiki::jobqueue_redis { 6380: slaveof => $slaveof }
    mediawiki::jobqueue_redis { 6381: slaveof => $slaveof }

    diamond::collector { 'Redis':
        settings => { instances => join($instances, ', ') }
    }
}
