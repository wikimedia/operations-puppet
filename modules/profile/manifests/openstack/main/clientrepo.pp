class profile::openstack::main::clientrepo(
    $version = hiera('profile::openstack::main::version'),
){
    class { '::profile::openstack::base::clientrepo':
        version => $version
    }
}
