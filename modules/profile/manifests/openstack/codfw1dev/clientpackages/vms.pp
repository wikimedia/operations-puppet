# profile used by VM instances in CloudVPS. Don't use it for HW servers.
# This is the codfw1dev deployment specific override of the base one.
class profile::openstack::codfw1dev::clientpackages::vms(
    String $version = lookup('profile::openstack::codfw1dev::version'),
) {
    requires_realm('labs')

    class { '::profile::openstack::base::clientpackages::vms':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages::vms'
}
