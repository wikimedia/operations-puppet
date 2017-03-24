class ores::redis(
    $queue_maxmemory,
    $cache_maxmemory,
    $password=undef,
    $slaveof=undef,
) {
    $common_settings = {
            bind                        => '0.0.0.0',
            appendonly                  => true,
            auto_aof_rewrite_min_size   => '512mb',
            client_output_buffer_limit  => 'slave 512mb 200mb 60',
            dir                         => '/srv/redis',
            no_appendfsync_on_rewrite   => true,
            save                        => '""',
            stop_writes_on_bgsave_error => false,
            slave_read_only             => false,
            tcp_keepalive               => 60,
    }
    $instance_settings = {
        '6379' => {
            maxmemory      => $queue_maxmemory,
            appendfilename => "${::hostname}-6379.aof",
            dbfilename     => "${::hostname}-6379.rdb",
        },
        '6380' => {
            maxmemory      => $cache_maxmemory,
            appendfilename => "${::hostname}-6380.aof",
            dbfilename     => "${::hostname}-6380.rdb",
        },
    }

    # If we specified a password use it
    if $password {
        $password_settings = {
            '6379' => {
                masterauth  => $password,
                requirepass => $password,
            },
            '6380' => {
                masterauth  => $password,
                requirepass => $password,
            },
        }
    } else {
        $password_settings = {}
    }
    # if we specified a slave, use it
    if $slaveof {
        $slave_settings = {
            '6379' => {
                slaveof => "${slaveof} 6379",
            },
            '6380' => {
                slaveof => "${slaveof} 6380",
            },
        }
    } else {
        $slave_settings = {}
    }
    $instances = keys($instance_settings)
    $instance_settings_real = deep_merge($instance_settings, $password_settings, $slave_settings)

    redis::instance { $instances:
        settings => $common_settings,
        map      => $instance_settings_real,
    }
    redis::monitoring::nrpe_instance{ $instances: }

    $uris = apply_format("localhost:%s/${password}", $instances)
    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') },
    }
}
