class role::jobqueue_redis {
    include ::standard
    include ::passwords::redis

    system::role { 'role::jobqueue_redis': }

    $password = $passwords::redis::main_password
    $slaveof = hiera('jobqueue_redis_slaveof', undef)
    $instances = apply_format("localhost:%s/${password}", [ 6379, 6380, 6381 ])

    mediawiki::jobqueue_redis { 6379: slaveof => $slaveof }
    mediawiki::jobqueue_redis { 6380: slaveof => $slaveof }
    mediawiki::jobqueue_redis { 6381: slaveof => $slaveof }

    diamond::collector { 'Redis':
        settings => { instances => join($instances, ', ') }
    }
}
