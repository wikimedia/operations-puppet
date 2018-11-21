class profile::openstack::eqiad1::serverpackages(
    $version = hiera('profile::openstack::eqiad1::version'),
){
    class { '::profile::openstack::base::serverpackages':
        version => $version
    }
}
