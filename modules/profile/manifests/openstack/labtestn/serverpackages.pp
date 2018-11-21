class profile::openstack::labtestn::serverpackages(
    $version = hiera('profile::openstack::labtestn::version'),
){
    class { '::profile::openstack::base::serverpackages':
        version => $version
    }
    contain '::profile::openstack::base::serverpackages'
}
