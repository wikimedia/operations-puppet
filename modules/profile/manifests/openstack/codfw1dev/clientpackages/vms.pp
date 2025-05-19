# SPDX-License-Identifier: Apache-2.0
# profile used by VM instances in CloudVPS. Don't use it for HW servers.
# This is the codfw1dev deployment specific override of the base one.
class profile::openstack::codfw1dev::clientpackages::vms() {
    requires_realm('labs')

    class { '::profile::openstack::base::clientpackages::vms':
    }
    contain '::profile::openstack::base::clientpackages::vms'
}
