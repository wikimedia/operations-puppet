class profile::openstack::base::clientpackages(
    String $version = hiera('profile::openstack::base::version'),
) {
    class { '::openstack::clientpackages::common': }
    class { "::openstack::clientpackages::${version}::${::lsbdistcodename}": }
}
