class profile::openstack::codfw1dev::serverpackages(
    $version = hiera('profile::openstack::codfw1dev::version'),
){
    class { '::profile::openstack::base::serverpackages':
        version => $version
    }
    contain '::profile::openstack::base::serverpackages'
}
