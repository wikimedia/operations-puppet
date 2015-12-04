# == Define: mediawiki::jobqueue_redis
#
# Provisions a redis queue server instance for the MediaWiki job queue.
#
# === Parameters
#
# [*port*]
#   Port Redis should listen on. Defaults to the resource title.
#
# [*slaveof*]
#   Can be either unset (the default) if this instance should be a master,
#   or set to a string with format "host" or "host port", to make this
#   instance a slave.
#
# === Example
#
#  mediawiki::jobqueue_redis { 6379:
#    slaveof => 'rdb1007',
#  }
#
define mediawiki::jobqueue_redis(
    $port    = $title,
    $slaveof = undef
) {
    include ::passwords::redis

    ferm::service { "redis-server-${port}":
        proto  => 'tcp',
        port   => $port,
        srange => '$ALL_NETWORKS',
    }

    $slaveof_actual = $slaveof ? {
        /^\S+ \d+$/ => $slaveof,
        /^\S+$/     => "${slaveof} ${port}",
        default     => undef,
    }

    redis::instance { $port:
        settings => {
            bind                        => '0.0.0.0',
            appendonly                  => true,
            auto_aof_rewrite_min_size   => '512mb',
            client_output_buffer_limit  => 'slave 512mb 200mb 60',
            dir                         => '/srv/redis',
            masterauth                  => $passwords::redis::main_password,
            maxmemory                   => '8Gb',
            no_appendfsync_on_rewrite   => true,
            requirepass                 => $passwords::redis::main_password,
            save                        => '""',
            stop_writes_on_bgsave_error => false,
            slave_read_only             => false,
            appendfilename              => "${::hostname}-${port}.aof",
            dbfilename                  => "${::hostname}-${port}.rdb",
            slaveof                     => $slaveof_actual,
        },
    }
}
