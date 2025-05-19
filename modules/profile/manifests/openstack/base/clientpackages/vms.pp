# SPDX-License-Identifier: Apache-2.0
# profile used by VM instances in CloudVPS. Don't use it for HW servers.
class profile::openstack::base::clientpackages::vms() {
    requires_realm('labs')
    class { '::openstack::clientpackages::vms::common': }
}
