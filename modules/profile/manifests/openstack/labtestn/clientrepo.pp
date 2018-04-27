class profile::openstack::labtestn::clientrepo(
    $version = hiera('profile::openstack::labtestn::version'),
){
    class { '::profile::openstack::base::clientrepo':
        version => $version
    }
}
