class profile::openstack::base::keystone::hooks(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class { '::openstack::keystone::hooks':
        version => $version,
    }
    contain '::openstack::keystone::hooks'
}
