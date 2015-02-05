# role/redis.pp
# db::redis

# Virtual resource for the monitoring server
@monitoring::group { 'redis_eqiad':
    description => 'eqiad Redis',
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

    if $::realm == 'production' {

        class { '::redis':
            maxmemory         => $maxmemory,
            dir               => $dir,
            persist           => 'aof',
            redis_replication => $redis_replication,
            password          => $passwords::redis::main_password,
        }

        include redis::ganglia
    }

    if $::realm == 'labs' {

        class { '::redis':
            maxmemory                 => '500mb',
            persist                   => 'aof',
            redis_replication         => undef,
            password                  => $::passwords::redis::main_password,
            dir                       => $dir,
            auto_aof_rewrite_min_size => '64mb',
        }
    }
}
