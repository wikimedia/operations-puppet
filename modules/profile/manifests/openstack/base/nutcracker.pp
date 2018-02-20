class profile::openstack::base::nutcracker(
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
) {
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $memcached_servers = $labweb_ips.map |$ip| { "${ip}:11000:1" }

    class {'::profile::nutcracker':
        memcached_servers => $memcached_servers,
        redis_servers     => [],
        monitor_port      => 0,
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
