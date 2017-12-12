class profile::openstack::base::cloudrepo(
    $version = hiera('profile::openstack::base::version'),
){
    class { '::openstack::cloudrepo':
        version => $version,
    }
    contain '::openstack::cloudrepo'
}
