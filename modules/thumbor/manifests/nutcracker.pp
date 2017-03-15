# Class thumbor::nutcracker
#
# Configures nutcracker for thumbor
#
# === Parameters
#
# [*thumbor_memcached_servers*]
#   List of memcached servers to point thumbor's nutcracker to.
#
class thumbor::nutcracker(
    $thumbor_memcached_servers = {}
    ) {
    include ::nutcracker::monitoring

    $pools = {
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
            servers              => $thumbor_memcached_servers,
        },
    }

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => $pools,
    }

}
