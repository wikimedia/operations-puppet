class role::jobqueue_redis {
    include ::standard

    system::role { 'role::jobqueue_redis': }

    $slaveof = hiera('jobqueue_redis_slaveof', undef)

    mediawiki::jobqueue_redis { 6379: slaveof => $slaveof }
    mediawiki::jobqueue_redis { 6380: slaveof => $slaveof }
    mediawiki::jobqueue_redis { 6381: slaveof => $slaveof }
}
