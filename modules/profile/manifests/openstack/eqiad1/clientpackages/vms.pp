# profile used by VM instances in CloudVPS. Don't use it for HW servers.
# This is the eqiad1 deployment specific override of the base one.
class profile::openstack::eqiad1::clientpackages::vms() {
    requires_realm('labs')

    class { '::profile::openstack::base::clientpackages::vms':
    }
    contain '::profile::openstack::base::clientpackages::vms'
}
