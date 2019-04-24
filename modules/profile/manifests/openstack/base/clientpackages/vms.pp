# profile used by VM instances in CloudVPS. Don't use it for HW servers.
class profile::openstack::base::clientpackages::vms(
    String $version = lookup('profile::openstack::base::version'),
) {
    requires_realm('labs')
    class { '::openstack::clientpackages::vms::common': }
    class { "::openstack::clientpackages::vms::${version}::${::lsbdistcodename}": }
}
