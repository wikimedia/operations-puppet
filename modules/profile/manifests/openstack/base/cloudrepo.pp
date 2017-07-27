class profile::openstack::base::cloudrepo(
    $version = hiera('profile::openstack::version'),
){
    class { '::openstack2::cloudrepo':
        version => $version,
    }
}
