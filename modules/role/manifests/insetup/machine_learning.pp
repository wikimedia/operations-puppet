# SPDX-License-Identifier: Apache-2.0
class role::insetup::machine_learning {
    system::role { 'insetup::machine_learning':
        ensure      => 'present',
        description => 'Host being setup by ML SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
