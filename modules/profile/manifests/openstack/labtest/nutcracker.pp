class profile::openstack::labtest::nutcracker(
    $labweb_hosts = hiera('profile::openstack::labtest::labweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        labweb_hosts => $labweb_hosts,
    }
}
