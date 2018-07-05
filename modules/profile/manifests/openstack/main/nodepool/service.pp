class profile::openstack::main::nodepool::service(
    $keystone_host = hiera('profile::openstack::main::keystone_host'),
    ) {

    class {'::profile::openstack::base::nodepool::service':
        keystone_host => $keystone_host,
    }

    class {'::profile::openstack::base::nodepool::monitor':}
}
