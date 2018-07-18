class profile::openstack::labtestn::cloudrepo(
    $version = hiera('profile::openstack::labtestn::version'),
){
    class { '::profile::openstack::base::cloudrepo':
        version => $version
    }
    contain '::profile::openstack::base::cloudrepo'
}
