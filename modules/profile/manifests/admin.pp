# SPDX-License-Identifier: Apache-2.0
# @summary wrapper profile for the admin class
class profile::admin (
    Array[String[1]] $groups          = lookup('profile::admin::groups'),
    Array[String[1]] $groups_no_ssh   = lookup('profile::admin::groups_no_ssh'),
    Array[String[1]] $always_groups   = lookup('profile::admin::always_groups'),
    Boolean          $purge_sudoers_d = lookup('profile::admin::purge_sudoers_d'),
    Boolean          $managehome      = lookup('profile::admin::managehome'),
    Boolean          $managelingering = lookup('profile::admin::managelingering'),
) {
    class {'sudo':
        purge_sudoers_d => $purge_sudoers_d,
    }
    class {'admin':
        * => wmflib::dump_params(['name', 'purge_sudoers_d'])
    }
}
