class profile::openstack::base::keystone::hooks(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class { 'openstack2::keystone::hooks':
        version => $version,
    }
}
