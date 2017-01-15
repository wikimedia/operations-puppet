# This role sets up a redis node for use by tool-labs
# Restricts usage of certain commands, to prevent
# people from trampling on others' keys
# Uses default amount of RAM (1G) specified by redis class

class toollabs::redis (
    $maxmemory = '12GB',
) {

    include ::toollabs::infrastructure
    include ::redis::client::python
    include ::labs_lvm

    package { 'python-virtualenv':
        ensure => latest,
    }

    labs_lvm::volume { 'redis-disk':
        mountat => '/srv',
        size    => '100%FREE',
    }

    $active_redis = hiera('active_redis')
    if $active_redis != $::fqdn {
        $slaveof = "${active_redis} 6379"
    } else {
        $slaveof = undef
    }

    redis::instance { 6379:
        settings => {
            client_output_buffer_limit  => 'slave 512mb 200mb 60',
            dbfilename                  => "${::hostname}-6379.rdb",
            dir                         => '/srv/redis',
            maxmemory                   => $maxmemory,
            maxmemory_policy            => 'allkeys-lru',
            maxmemory_samples           => 5,
            save                        => '300 100',
            slave_read_only             => false,
            stop_writes_on_bgsave_error => false,
            slaveof                     => $slaveof,
            bind                        => '0.0.0.0',
            rename_command              => {
                'CLIENT'    => '""',
                'CONFIG'    => '""',
                'DEBUG'     => '""',
                'FLUSHALL'  => '""',
                'FLUSHDB'   => '""',
                'KEYS'      => '""',
                'MONITOR'   => '""',
                'RANDOMKEY' => '""',
                'SHUTDOWN'  => '""',
                'SLAVEOF'   => '""',
            },
        },
        require  => Labs_lvm::Volume['redis-disk'],
    }

    diamond::collector { 'Redis':
        require => Class['::redis::client::python'],
    }
}
