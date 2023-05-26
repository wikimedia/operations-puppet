# SPDX-License-Identifier: Apache-2.0
class role::insetup::container {
    system::role { 'insetup::container':
        ensure      => 'present',
        description => 'Container build base',
    }

    include profile::base::production
    include profile::firewall
}
