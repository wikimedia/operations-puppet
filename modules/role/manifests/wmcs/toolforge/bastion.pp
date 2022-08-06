# SPDX-License-Identifier: Apache-2.0
class role::wmcs::toolforge::bastion {
    system::role { $name:
        description => 'Toolforge bastion'
    }

    # temporary role until usages via ENC have been updated
    include ::role::wmcs::toolforge::grid::bastion
}
