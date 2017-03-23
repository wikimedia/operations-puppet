define profile::jobqueue_redis::instances($ip, $shards = {}) {
    include ::passwords::redis
    $replica_state_file = "/etc/redis/replica/${title}-state.conf"
    redis::instance { $title:
        settings => {
            bind                        => '0.0.0.0',
            appendonly                  => true,
            auto_aof_rewrite_min_size   => '512mb',
            client_output_buffer_limit  => 'slave 2048mb 200mb 60',
            dir                         => '/srv/redis',
            masterauth                  => $passwords::redis::main_password,
            maxmemory                   => '8Gb',
            no_appendfsync_on_rewrite   => true,
            requirepass                 => $passwords::redis::main_password,
            save                        => '""',
            stop_writes_on_bgsave_error => false,
            slave_read_only             => false,
            appendfilename              => "${::hostname}-${title}.aof",
            dbfilename                  => "${::hostname}-${title}.rdb",
            'include'                   => $replica_state_file,
        },
    }

    confd::file { $replica_state_file:
        ensure     => present,
        prefix     => '/discovery/appservers-rw',
        watch_keys => ['/'],
        uid        => 0,
        gid        => 0,
        content    => template('profile/jobqueue_redis/statefile.tpl.erb'),
    }

}
