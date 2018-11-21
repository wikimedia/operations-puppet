class profile::openstack::main::serverpackages(
    String $version = lookup('profile::openstack::main::version'),
){
    class { '::profile::openstack::base::serverpackages':
        version => $version,
    }
}
