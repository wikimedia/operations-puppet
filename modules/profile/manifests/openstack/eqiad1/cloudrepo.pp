class profile::openstack::eqiad1::cloudrepo(
    $version = hiera('profile::openstack::eqiad1::version'),
){
    class { '::profile::openstack::base::cloudrepo':
        version => $version
    }
}
