class profile::openstack::base::clientpackages(
    String $version = lookup('profile::openstack::base::version'),
) {
    class { "::openstack::clientpackages::${version}::${::lsbdistcodename}": }
}
