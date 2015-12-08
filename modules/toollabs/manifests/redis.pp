# Class: toollabs::redis
#
# This role sets up a redis node for use by tool-labs
# Restricts usage of certain commands, to prevent
# people from trampling on others' keys
# Uses default amount of RAM (1G) specified by redis class
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::redis (
    $maxmemory = '12GB',
) inherits toollabs {
    include toollabs::infrastructure
    include ::redis::client::python

    # $active_redis inherited from toollabs
    if $active_redis != $::hostname {
        $slaveof = $active_redis
    } else {
        $slaveof = undef
    }

    include labs_lvm
    labs_lvm::volume { 'redis-disk':
        mountat => '/srv',
        size    => '100%FREE',
    }

    redis::instance { 6379:
        settings => {
            auto_aof_rewrite_min_size   => '512mb',
            client_output_buffer_limit  => 'slave 512mb 200mb 60',
            dbfilename                  => "${::hostname}-6379.rdb",
            dir                         => '/srv/redis',
            maxmemory                   => '12GB',
            maxmemory_policy            => 'allkeys-lru',
            maxmemory_samples           => 5,
            no_appendfsync_on_rewrite   => true,
            save                        => '300 100',
            slave_read_only             => false,
            stop_writes_on_bgsave_error => false,
            appendfilename              => "${::hostname}-6379.aof",
            slaveof                     => $slaveof,
            rename_command              => {
                CLIENT    => '""',
                CONFIG    => '""',
                DEBUG     => '""',
                FLUSHALL  => '""',
                FLUSHDB   => '""',
                KEYS      => '""',
                MONITOR   => '""',
                RANDOMKEY => '""',
                SHUTDOWN  => '""',
                SLAVEOF   => '""',
            },
            require                     => Labs_lvm::Volume['redis-disk'],
        },
    }

    package { 'python-virtualenv':
        ensure => latest,
    }
}
