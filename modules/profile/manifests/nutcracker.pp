# Class profile::nutcracker
#
# Configures a generic nutcracker instance
class profile::nutcracker(
    $redis_pools = hiera('profile::nutcracker::redis_pools'),
    $memcached_pools = hiera('profile::nutcracker::memcached_pools'),
    $monitor_port = hiera('profile::nutcracker::monitor_port'), # set to 0 if no port available
) {
    include ::passwords::redis

    # Default settings that should be ok for any pool
    # pools *need* to define just the listen and server_map entries
    $redis_base_settings = {
        auto_eject_hosts     => true,
        distribution         => 'ketama',
        redis                => true,
        redis_auth           => $::passwords::redis::main_password,
        hash                 => 'md5',
        server_connections   => 1,
        server_failure_limit => 3,
        server_retry_timeout => to_milliseconds('30s'),
        timeout              => 1000,
    }

    $memcached_base_settings = {
        auto_eject_hosts     => true,
        distribution         => 'ketama',
        hash                 => 'md5',
        preconnect           => true,
        server_connections   => 1,
        server_failure_limit => 3,
        server_retry_timeout => to_milliseconds('30s'),
        timeout              => 250,
    }

    # TODO: this is now a parser function, should be doable with map()
    # when we enable the future parser
    $pools = nutcracker_pools($redis_pools, $memcached_pools, $redis_base_settings, $memcached_base_settings)
    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => $pools,
    }

    include ::profile::prometheus::nutcracker_exporter
    class { '::nutcracker::monitoring':
        port => $monitor_port,
    }


    ferm::rule { 'skip_nutcracker_conntrack_out':
        desc  => 'Skip outgoing connection tracking for Nutcracker',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto tcp sport (6378:6382 11212) NOTRACK;',
    }

    ferm::rule { 'skip_nutcracker_conntrack_in':
        desc  => 'Skip incoming connection tracking for Nutcracker',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto tcp dport (6378:6382 11212) NOTRACK;',
    }

}
