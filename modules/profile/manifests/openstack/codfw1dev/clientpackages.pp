class profile::openstack::codfw1dev::clientpackages(
    String $version = hiera('profile::openstack::codfw1dev::version'),
){
    class { '::profile::openstack::base::clientpackages':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages'
}
