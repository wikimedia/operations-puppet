# SPDX-License-Identifier: Apache-2.0
# @summary install production specific classes for WMCS-owned hosts
# @param enable weather to enable or disable this profile.  This is most often used to disable this profile
#   in cloud environments which directly include a role:: class
class profile::base::cloud_production (
    Boolean $enable = lookup('profile::base::production::enable'),  # Use the same base::production key
) {
    if $enable {
        # Add additional WMCS-specific setting for hosts in the production realm
        include profile::cumin::cloud_target

        class { 'prometheus::node_kernel_panic':
            ensure => 'present',
        }
    }
}
