# SPDX-License-Identifier: Apache-2.0
class role::insetup::core_platform {
    system::role { 'insetup::core_platform':
        ensure      => 'present',
        description => 'Host being setup by Core Platform SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
