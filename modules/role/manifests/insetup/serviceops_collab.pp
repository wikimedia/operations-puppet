# SPDX-License-Identifier: Apache-2.0
class role::insetup::serviceops_collab {
    system::role { 'insetup::serviceops_collab':
        ensure      => 'present',
        description => 'Host being setup by Serviceops-collab SREs',
    }

    include profile::base::production
    include profile::firewall
}
