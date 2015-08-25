# Class mediawiki::nutcracker
#
# Configures nutcracker for mediawiki
class mediawiki::nutcracker {
    include ::nutcracker::monitoring
    include ::passwords::redis

    $nutcracker_pools = {
        'memcached'     => {
            auto_eject_hosts     => true,
            distribution         => 'ketama',
            hash                 => 'md5',
            listen               => '127.0.0.1:11212',
            preconnect           => true,
            server_connections   => 1,
            server_failure_limit => 3,
            server_retry_timeout => to_milliseconds('30s'),
            timeout              => 250,
            servers              => hiera('mediawiki_memcached_servers'),
        },
        'mc-unix'       => {
            auto_eject_hosts     => true,
            distribution         => 'ketama',
            hash                 => 'md5',
            listen               => '/var/run/nutcracker/nutcracker.sock 0666',
            preconnect           => true,
            server_connections   => 1,
            server_failure_limit => 3,
            server_retry_timeout => to_milliseconds('30s'),
            timeout              => 250,
            servers              => hiera('mediawiki_memcached_servers'),
        },
        'session-redis' => {
            auto_eject_hosts     => true,
            distribution         => 'ketama',
            redis                => true,
            redis_auth           => $passwords::redis::main_password,
            hash                 => 'md5',
            listen               => '127.0.0.1:6380',
            preconnect           => true,
            server_connections   => 1,
            server_failure_limit => 3,
            server_retry_timeout => to_milliseconds('30s'),
            timeout              => 1000,
            servers              => hiera('mediawiki_session_redis_servers'),
        },
    }

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => $nutcracker_pools,
    }

}
