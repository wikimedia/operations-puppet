# role/redis.pp
# db::redis
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
        port   => '6379:6381',
        srange => '$ALL_NETWORKS',
    }

    $defaults = {
        appendonly                  => true,
        auto_aof_rewrite_min_size   => '512mb',
        client_output_buffer_limit  => 'slave 512mb 200mb 60',
        dir                         => '/srv/redis',
        masterauth                  => $passwords::redis::main_password,
        maxmemory                   => '10Gb',
        no_appendfsync_on_rewrite   => true,
        requirepass                 => $passwords::redis::main_password,
        save                        => '',
        stop_writes_on_bgsave_error => false,
        slave_read_only             => false,
    }

    if $::hostname == 'rdb1008' {
        redis::instance { 6379:
            settings => merge($defaults, {
                appendfilename              => "${::hostname}-6379.aof",
                dbfilename                  => "${::hostname}-6379.rdb",
                slaveof                     => 'rdb1007 6379',
            }),
        }

        redis::instance { 6380:
            settings => merge($defaults, {
                appendfilename              => "${::hostname}-6380.aof",
                dbfilename                  => "${::hostname}-6380.rdb",
                slaveof                     => 'rdb1007 6380',
            }),
        }

        redis::instance { 6381:
            settings => merge($defaults, {
                appendfilename              => "${::hostname}-6381.aof",
                dbfilename                  => "${::hostname}-6381.rdb",
                slaveof                     => 'rdb1007 6381',
            }),
        }
    } elsif $::hostname == 'rdb1007' {
        redis::instance { 6379:
            settings => merge($defaults, {
                appendfilename              => "${::hostname}-6379.aof",
                dbfilename                  => "${::hostname}-6379.rdb",
            }),
        }

        redis::instance { 6380:
            settings => merge($defaults, {
                appendfilename              => "${::hostname}-6380.aof",
                dbfilename                  => "${::hostname}-6380.rdb",
            }),
        }

        redis::instance { 6381:
            settings => merge($defaults, {
                appendfilename              => "${::hostname}-6381.aof",
                dbfilename                  => "${::hostname}-6381.rdb",
            }),
        }
    } else {
        class { '::redis::legacy':
            maxmemory         => $maxmemory,
            dir               => $dir,
            persist           => 'aof',
            redis_replication => $redis_replication,
            password          => $passwords::redis::main_password,
        }

        if $::standard::has_ganglia {
            include redis::ganglia
        }
    }
}
