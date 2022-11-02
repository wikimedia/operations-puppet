# SPDX-License-Identifier: Apache-2.0
class role::insetup::serviceops {
    system::role { 'insetup::serviceops':
        ensure      => 'present',
        description => 'Host being setup by Serviceops SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
