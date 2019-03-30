class profile::openstack::eqiad1::nutcracker(
    $labweb_hosts = hiera('profile::openstack::eqiad1::labweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        labweb_hosts => hiera('profile::openstack::eqiad1::labweb_hosts'),
    }
}
