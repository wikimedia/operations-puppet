class profile::openstack::codfw1dev::cloudweb_mcrouter(
    Array[Stdlib::Fqdn] $cloudweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    Stdlib::Port        $mcrouter_port  = lookup('profile::openstack::codfw1dev::cloudweb::mcrouter_port'),
    Integer             $memcached_size = lookup('profile::openstack::codfw1dev::cloudweb_memcached_size'),

) {
    class {'profile::openstack::base::cloudweb_mcrouter':
        cloudweb_hosts => $cloudweb_hosts,
        mcrouter_port  => $mcrouter_port,
        memcached_size => $memcached_size,
    }
}
