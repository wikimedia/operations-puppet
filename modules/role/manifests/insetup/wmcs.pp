# SPDX-License-Identifier: Apache-2.0
class role::insetup::wmcs {
    system::role { 'insetup::wmcs':
        ensure      => 'present',
        description => 'Host being setup by WMCS SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
