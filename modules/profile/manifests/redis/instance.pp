# == Class: profile::redis::instance
#
# Installs and configures a Redis instance.
#
# === Parameters
#
# [*settings*]
#   A hash containing configuration values for Redis. It will override
#   the related parameters of the default base settings.
#
# [*port*]
#   TCP port that Redis will listen on.
#   Default: 6379
#
class profile::redis::instance (
    $settings = {},
    $port     = 6379,
) {
    include passwords::redis

    $base_settings = {
        bind                        => '0.0.0.0',
        auto_aof_rewrite_min_size   => '512mb',
        client_output_buffer_limit  => 'slave 512mb 200mb 60',
        dir                         => '/srv/redis',
        dbfilename                  => "${::hostname}-${port}.rdb",
        masterauth                  => $passwords::redis::main_password,
        maxmemory                   => '500Mb',
        maxmemory_policy            => 'volatile-lru',
        maxmemory_samples           => 5,
        no_appendfsync_on_rewrite   => true,
        requirepass                 => $passwords::redis::main_password,
        save                        => '300 100',
        slave_read_only             => false,
        stop_writes_on_bgsave_error => false,
    }

    $redis_settings = merge($base_settings, $settings)

    redis::instance{ ${port}:
        ensure   => present,
        settings => $redis_settings,
    }
}
