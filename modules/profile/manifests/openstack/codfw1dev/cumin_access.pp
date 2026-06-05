# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::cumin_access (
    Hash[String[1], String[1]] $project_and_security_group_for_cumin_access = lookup('profile::openstack::codfw1dev::project_and_security_group_for_cumin_access'),
) {
    class { '::profile::openstack::base::cumin_access':
        project_and_security_group_for_cumin_access => $project_and_security_group_for_cumin_access,
    }
}
