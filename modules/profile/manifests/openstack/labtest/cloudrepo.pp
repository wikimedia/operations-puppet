class profile::openstack::labtest::cloudrepo(
    $version = hiera('profile::openstack::labtest::version'),
){
    class { '::profile::openstack::base::cloudrepo':
        version => $version
    }
    contain '::profile::openstack::base::cloudrepo'
}
