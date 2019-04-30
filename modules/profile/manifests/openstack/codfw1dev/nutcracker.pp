class profile::openstack::codfw1dev::nutcracker(
    $labweb_hosts = hiera('profile::openstack::codfw1dev::labweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        labweb_hosts => $labweb_hosts,
    }
}
