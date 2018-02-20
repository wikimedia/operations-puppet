class profile::openstack::base::nutcracker(
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
) {
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $memcached_servers = $labweb_ips.map |$ip| { "${ip}:11000:1" }

    class {"::profile::nutcracker":
        memcached_servers => $memcached_servers,
    }

    class { '::memcached':
    }
}
