# SPDX-License-Identifier: Apache-2.0
class role::insetup::unowned {
    system::role { 'insetup::unowned':
        ensure      => 'present',
        description => 'Host being setup',
    }

    include profile::base::production
    include profile::base::firewall
}
