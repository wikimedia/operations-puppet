# SPDX-License-Identifier: Apache-2.0
class role::insetup::infrastructure_foundations {
    system::role { 'insetup::infrastructure_foundations':
        ensure      => 'present',
        description => 'Host being setup by Infrastructure Foundations SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
