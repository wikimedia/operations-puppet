class profile::openstack::labtestn::clientpackages(
    String $version = hiera('profile::openstack::labtestn::version'),
){
    class { '::profile::openstack::base::clientpackages':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages'
}
