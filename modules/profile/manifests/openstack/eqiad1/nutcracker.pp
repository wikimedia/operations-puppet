class profile::openstack::eqiad1::nutcracker(
    Array[Stdlib::Fqdn] $cloudweb_hosts = lookup('profile::openstack::eqiad1::cloudweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        cloudweb_hosts => $cloudweb_hosts,
    }
}
