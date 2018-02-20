class profile::openstack::labtestn::nutcracker(
    $labweb_hosts = hiera('profile::openstack::labtestn::labweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        labweb_hosts => hiera('profile::openstack::main::labweb_hosts'),
    }
}
