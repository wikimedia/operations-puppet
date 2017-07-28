class profile::openstack::base::cloudrepo(
    $version = hiera('profile::openstack::base::version'),
){
    class { '::openstack2::cloudrepo':
        version => $version,
    }
}
