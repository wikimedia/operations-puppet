class profile::openstack::labtest::serverpackages(
    $version = hiera('profile::openstack::labtest::version'),
){
    class { '::profile::openstack::base::serverpackages':
        version => $version
    }
    contain '::profile::openstack::base::serverpackages'
}
