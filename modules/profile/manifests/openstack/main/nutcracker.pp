class profile::openstack::main::nutcracker(
    $labweb_hosts = hiera('profile::openstack::main::labweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        labweb_hosts => hiera('profile::openstack::main::labweb_hosts'),
    }
}
