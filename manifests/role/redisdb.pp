# role/redis.pp
# db::redis

# Virtual resource for the monitoring server
@monitoring::group { 'redis_eqiad':
    description => 'eqiad Redis',
}

@monitoring::group { 'redis_codfw':
    description => 'codfw Redis',
}

class role::db::redis (
    $maxmemory         = inline_template("<%= (Float(memorysize.split[0]) * 0.82).round %>Gb"),
    $redis_replication = undef,
    $dir               = '/srv/redis'
) {

    system::role { 'db::redis':
        description => 'Redis server',
    }

    include standard
    include passwords::redis

    ferm::service { 'redis-server':
        proto   => 'tcp',
        port    => '6379',
        srange  => '$ALL_NETWORKS',
    }

    class { '::redis':
        maxmemory         => $maxmemory,
        dir               => $dir,
        persist           => 'aof',
        redis_replication => $redis_replication,
        password          => $passwords::redis::main_password,
        # previously, this was set on labs and not set on production:
        # should move to hiera?  If so, where?
        # auto_aof_rewrite_min_size => '64mb',
    }

    if $::realm == 'production' {
        include redis::ganglia
    }

}
