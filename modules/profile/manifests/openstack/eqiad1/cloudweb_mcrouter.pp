class profile::openstack::eqiad1::cloudweb_mcrouter(
    Array[Stdlib::Fqdn] $cloudweb_hosts = lookup('profile::openstack::eqiad1::cloudweb_hosts'),
    Stdlib::Port        $mcrouter_port  = lookup('profile::openstack::eqiad1::cloudweb::mcrouter_port'),
    Integer             $memcached_size = lookup('profile::openstack::eqiad1::cloudweb_memcached_size'),
    String[1]           $memcached_user = lookup('profile::openstack::eqiad1::cloudweb::memcached_user'),
) {
    class {'profile::openstack::base::cloudweb_mcrouter':
        cloudweb_hosts => $cloudweb_hosts,
        mcrouter_port  => $mcrouter_port,
        memcached_size => $memcached_size,
        memcached_user => $memcached_user,
    }
}
