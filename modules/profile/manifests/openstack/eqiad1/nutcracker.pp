class profile::openstack::eqiad1::nutcracker(
    $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        labweb_hosts => lookup('profile::openstack::eqiad1::labweb_hosts'),
    }
}
