# role/redis.pp
# db::redis

# Virtual resource for the monitoring server
@monitoring::group { 'redis_eqiad':
    description => 'eqiad Redis',
}

@monitoring::group { 'redis_codfw':
    description => 'codfw Redis',
}

class role::redisdb (
    $maxmemory         = inline_template('<%= (Float(@memorysize.split[0]) * 0.82).round %>Gb'),
    $redis_replication = undef,
    $dir               = '/srv/redis'
) {

    system::role { 'db::redis':
        description => 'Redis server',
    }

    include standard
    include passwords::redis

    ferm::service { 'redis-server':
        proto  => 'tcp',
        port   => '6379',
        srange => '$ALL_NETWORKS',
    }

    if $::hostname == 'rdb1008' {
        redis::instance { 6379:
            settings => {
                appendfilename              => "${::hostname}_6379.aof",
                appendonly                  => true,
                auto_aof_rewrite_min_size   => '512mb',
                client_output_buffer_limit  => 'slave 512mb 200mb 60',
                dbfilename                  => "${::hostname}_6379.rdb",
                dir                         => '/srv/redis',
                masterauth                  => $passwords::redis::main_password,
                maxmemory                   => $maxmemory,
                no_appendfsync_on_rewrite   => true,
                requirepass                 => $passwords::redis::main_password,
                save                        => '',
                slave_read_only             => false,
                slaveof                     => 'rdb1007 6379',
                stop_writes_on_bgsave_error => false,
            }
        }
    } else {
        class { '::redis::legacy':
            maxmemory         => $maxmemory,
            dir               => $dir,
            persist           => 'aof',
            redis_replication => $redis_replication,
        }

        if $::standard::has_ganglia {
            include redis::ganglia
        }
    }
}
