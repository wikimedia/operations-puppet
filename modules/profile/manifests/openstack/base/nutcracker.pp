# Class profile::openstack::base::nutcracker
#
# Configures a nutcracker instance with all labwebs in the memcached pool
#
class profile::openstack::base::nutcracker(
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
) {
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $memcached_servers = $labweb_ips.map |$ip| { "${ip}:11000:1" }

    $memcached_pools = {
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
    }

    class {'::profile::nutcracker':
        redis_pools     => {},
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
