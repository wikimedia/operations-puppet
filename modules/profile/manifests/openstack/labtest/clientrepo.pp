class profile::openstack::labtest::clientrepo(
    $version = hiera('profile::openstack::labtest::version'),
){
    class { '::profile::openstack::base::clientrepo':
        version => $version
    }
}
