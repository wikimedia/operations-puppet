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

    class {'::profile::mediawiki::nutcracker':
        memcached_servers => $memcached_servers,
        redis_shards      => $redis_shards,
        datacenters       => [],
    }

    class { '::memcached':
        size => $memcached_size,
    }

    class { '::profile::prometheus::memcached_exporter': }

    $labweb_ips_ferm = inline_template("(@resolve((<%= @labweb_hosts.join(' ') %>)) @resolve((<%= @labweb_hosts.join(' ') %>), AAAA))")
    ferm::service { 'horizon_memcached':
        proto  => 'tcp',
        port   => '11000',
        srange => $labweb_ips_ferm,
    }

    # Why doesn't profile::mediawiki::nutcracker handle this?
    file { '/var/run/nutcracker':
        ensure => 'directory',
        owner  => 'nutcracker',
        group  => 'nutcracker',
    }
}
