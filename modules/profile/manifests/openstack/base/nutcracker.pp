# Class profile::openstack::base::nutcracker
#
# Configures a nutcracker instance with all labwebs in the memcached pool
#
class profile::openstack::base::nutcracker(
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
) {
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $memcached_servers = $labweb_ips.map |$ip| { "${ip}:11000:1" }

    $redis_servers = $labweb_hosts.map |$host| {{ $host => {'host' => ipresolve($host, 4), 'port' => '6378' }}}
    $redis_shards = {'jobqueue' => {'eqiad' => $redis_servers}, 'sessions' => {'eqiad' => $redis_servers}}

    class {'::profile::mediawiki::nutcracker':
        memcached_servers => $memcached_servers,
        redis_shards      => $redis_shards,
        datacenters       => [],
    }

    class { '::memcached':
    }

    $labweb_ips_ferm = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    ferm::service { 'horizon_memcached':
        proto  => 'tcp',
        port   => '11000',
        srange => $labweb_ips_ferm
    }
}
