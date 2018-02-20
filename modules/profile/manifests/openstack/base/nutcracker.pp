# Class profile::openstack::base::nutcracker
#
# Configures a nutcracker instance with all labwebs in the memcached pool
#
class profile::openstack::base::nutcracker(
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
) {
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $memcached_pools = $labweb_ips.map |$ip| { "${ip}:11000:1" }

    class {'::profile::nutcracker':
        redis_pools     => [],
        memcached_pools => $memcached_pools,
        monitor_port    => 0,
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
