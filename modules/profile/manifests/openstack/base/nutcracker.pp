# SPDX-License-Identifier: Apache-2.0
# Class profile::openstack::base::nutcracker
#
# Configures a nutcracker instance with all labwebs in the memcached pool
#
class profile::openstack::base::nutcracker(
    Array[Stdlib::Fqdn] $labweb_hosts   = lookup('profile::openstack::base::labweb_hosts'),
    Hash[String,Hash]   $redis_shards   = lookup('profile::openstack::base::nutcracker::redis::shards'),
    Integer             $memcached_size = lookup('profile::openstack::base::nutcracker::memcached::size'),
) {
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $memcached_servers = $labweb_ips.map |$ip| { "${ip}:11000:1" }

    file { '/var/run/nutcracker':
        ensure => 'directory',
        owner  => 'nutcracker',
        group  => 'nutcracker',
    }

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
        server_retry_timeout => 30000,  # milliseconds
        timeout              => 1000,   # milliseconds
        server_map           => $redis_servers['eqiad'],
    }

    if $memcached_servers == [] {
        $nutcracker_pools = {
            'redis_eqiad' => $redis_eqiad_pool,
        }
    } else {
        $nutcracker_pools = {
            'memcached'     => {
                auto_eject_hosts     => true,
                distribution         => 'ketama',
                hash                 => 'md5',
                listen               => '127.0.0.1:11212',
                preconnect           => true,
                server_connections   => 1,
                server_failure_limit => 3,
                server_retry_timeout => 30000,  # milliseconds
                timeout              => 250,    # milliseconds
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
                server_retry_timeout => 30000,  # milliseconds
                timeout              => 250,    # milliseconds
                servers              => $memcached_servers,
            },

            'redis_eqiad'   =>  $redis_eqiad_pool,
        }
    }

    # Ship a tmpfiles.d configuration to create /run/nutcracker
    systemd::tmpfile { 'nutcracker':
        content => 'd /run/nutcracker 0755 nutcracker nutcracker - -'
    }

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => $nutcracker_pools,
    }

    systemd::unit{ 'nutcracker':
        content  => "[Service]\nCPUAccounting=yes\n",
        override => true,
    }

    profile::auto_restarts::service { 'nutcracker': }

    # monitor memcached if present, redis otherwise.
    if $memcached_servers != [] {
        class { '::nutcracker::monitoring':
            port => 11212
        }
    }
    else {
        class { '::nutcracker::monitoring':
            port   => 0,
            socket => "/var/run/nutcracker/redis_${::site}.sock",
        }
    }

    $labweb_ips_ferm = inline_template("(@resolve((<%= @labweb_hosts.join(' ') %>)) @resolve((<%= @labweb_hosts.join(' ') %>), AAAA))")
    ferm::service { 'horizon_memcached':
        proto  => 'tcp',
        port   => '11000',
        srange => $labweb_ips_ferm,
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
