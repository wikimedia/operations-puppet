class profile::openstack::base::serverpackages(
    String $version=lookup('profile::openstack::base::version'),
) {
    class { "::openstack::serverpackages::${version}::${::lsbdistcodename}": }
}
