# == Class: profile::redis::multidc_instance
#
# Installs and configures a Redis instance and it configures its slave
# acconding to the specification (shards) provided.
#
# === Parameters
#
# [*settings*]
#   A hash containing configuration values for Redis. It will override
#   the related parameters of the default base settings.
#
# [*shards*]
#   The configuration for master/slave relationship for each Redis shard.
#   Default: eqiad and codfw mediawiki shards specified in hiera
#
class profile::redis::multidc_instance (
    $settings     = hiera_hash('profile::redis::settings', {}),
    $eqiad_shards = hiera('mediawiki::redis_servers::eqiad'),
    $codfw_shards = hiera('mediawiki::redis_servers::codfw'),
) {

    include passwords::redis

    $base_settings = {
        bind                        => '0.0.0.0',
        auto_aof_rewrite_min_size   => '512mb',
        client_output_buffer_limit  => 'slave 512mb 200mb 60',
        dir                         => '/srv/redis',
        dbfilename                  => "${::hostname}-6379.rdb",
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

    $shards = {
        'eqiad' => $eqiad_shards,
        'codfw' => $codfw_shards,
    }

    if os_version('Debian >= jessie') {
        class { 'redis::multidc::ipsec':
            shards => $shards
        }
    }

    class { 'redis::multidc::instances':
        shards   => $shards,
        settings => $base_settings,
        map      => {
            '6380' => {
                dbfilename => "${::hostname}-6380.rdb",
            }
        }
    }

    # Monitoring

    # Declare monitoring for all redis instances
    redis::monitoring::instance { $::redis::multidc::instances::instances:
        settings => $base_settings,
        map      => $::redis::multidc::instances::replica_map,
    }

    # Firewall rules
    include ::ferm::ipsec_allow

    $redis_ports = join($::redis::multidc::instances::instances, ' ')

    ferm::service { 'multidc_redis':
        proto => 'tcp',
        port  => inline_template('(<%= @redis_ports %>)'),
    }
}
