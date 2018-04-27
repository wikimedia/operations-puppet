class profile::openstack::labtestn::cloudrepo(
    $version = hiera('profile::openstack::labtestn::version'),
){
    class { '::profile::openstack::base::clientrepo':
        version => $version
    }
}
