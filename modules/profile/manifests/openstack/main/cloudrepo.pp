class profile::openstack::main::cloudrepo(
    $version = hiera('profile::openstack::main::version'),
){
    class { '::profile::openstack::base::cloudrepo':
        version => $version
    }
}
