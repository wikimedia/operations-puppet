# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::cumin_access (
    Hash[String[1], String[1]] $project_and_security_group_for_cumin_access = lookup('profile::openstack::base::project_and_security_group_for_cumin_access'),
) {
    class { '::openstack::apply_security_groups':
        ensure                     => present,
        project_and_security_group => $project_and_security_group_for_cumin_access,
    }
}
