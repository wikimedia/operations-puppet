class profile::openstack::labtest::cloudrepo(
    $version = hiera('profile::openstack::labtest::version'),
){
    class { '::profile::openstack::base::clientrepo':
        version => $version
    }
}
