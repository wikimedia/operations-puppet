# = Class: quarry::redis
#
# Sets up a redis instance for use as caching and session storage
# by the Quarry frontends and also as working queue & results
# backend by the query runners.
class quarry::redis {
    redis::instance { '6379':
        settings => {
            dir            => '/srv/redis',
            maxmemory      => '2GB',
            appendonly     => 'yes',
            appendfilename => "${hostname}-6379.aof",
        }
    }
}

