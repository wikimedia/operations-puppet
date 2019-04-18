# Class profile::mediawiki::nutcracker
#
# Configures nutcracker for mediawiki
class profile::mediawiki::nutcracker(
    $redis_shards      = hiera('redis::shards'),
    $datacenters       = hiera('datacenters'),
    $memcached_servers = hiera('mediawiki_memcached_servers', []),
) {
    $redis_servers = $redis_shards['sessions']
    include ::passwords::redis
    include ::profile::prometheus::nutcracker_exporter

    $redis_eqiad_pool = {
        auto_eject_hosts     => true,
        distribution         => 'ketama',
        redis                => true,
        redis_auth           => $passwords::redis::main_password,
        hash                 => 'md5',
        listen               => '/var/run/nutcracker/redis_eqiad.sock 0666',
        server_connections   => 1,
        server_failure_limit => 3,
        server_retry_timeout => to_milliseconds('30s'),
        timeout              => 1000,
        server_map           => $redis_servers['eqiad'],
    }

    if $memcached_servers == [] {
        $pools = {
            'redis_eqiad' => $redis_eqiad_pool,
        }
    } else {
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
                servers              => $memcached_servers,
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
                servers              => $memcached_servers,
            },

            'redis_eqiad'   =>  $redis_eqiad_pool,
        }
    }

    if member($datacenters, 'codfw') {
        $additional_pools = {
            'redis_codfw'           =>  {
                auto_eject_hosts     => true,
                distribution         => 'ketama',
                redis                => true,
                redis_auth           => $passwords::redis::main_password,
                hash                 => 'md5',
                listen               => '/var/run/nutcracker/redis_codfw.sock 0666',
                server_connections   => 1,
                server_failure_limit => 3,
                server_retry_timeout => to_milliseconds('30s'),
                timeout              => 1000,
                server_map           => $redis_servers['codfw'],
            },
        }
    }
    else {
        $additional_pools = {}
    }

    $nutcracker_pools = merge($pools, $additional_pools)

    # In jessie we used a custom nutcracker package which shipped a tmpfiles.d
    # config to create /run/nutcracker. Starting with stretch we're using the
    # unmodified Debian package, so ship the tmpfiles.d configuration via systemd::tmpfile
    if os_version('debian >= stretch') {
        systemd::tmpfile { 'nutcracker':
            content => 'd /run/nutcracker 0755 nutcracker nutcracker - -'
        }
    }

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => $nutcracker_pools,
    }

    class { '::nutcracker::monitoring': }


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
