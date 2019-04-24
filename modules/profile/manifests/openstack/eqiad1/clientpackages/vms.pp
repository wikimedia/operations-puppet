# profile used by VM instances in CloudVPS. Don't use it for HW servers.
# This is the eqiad1 deployment specific override of the base one.
class profile::openstack::eqiad1::clientpackages::vms(
    String $version = hiera('profile::openstack::eqiad1::version'),
) {
    requires_realm('labs')

    class { '::profile::openstack::base::clientpackages::vms':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages::vms'
}
